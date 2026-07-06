import sys
import os
import inspect
import tkinter as tk
import time
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel

# -----------------------------------------------------------------------------
# MONKEY-PATCHING PLAYWRIGHT TO MANAGE WINDOW LAYOUT
# -----------------------------------------------------------------------------
from playwright._impl._browser_type import BrowserType
from playwright._impl._browser import Browser
from playwright._impl._browser_context import BrowserContext
from playwright._impl._page import Page

original_launch = BrowserType.launch
original_new_context = Browser.new_context
original_goto = Page.goto

def patched_launch(self, *args, **kwargs):
    # Only apply positioning if running headed (headless=False)
    if not kwargs.get("headless", False):
        thread_id = None
        # Inspect the calling stack to find thread_id inside run_session_thread
        for frame_info in inspect.stack():
            if frame_info.function == 'run_session_thread':
                thread_id = frame_info.frame.f_locals.get('thread_id')
                break
        
        if thread_id in (1, 2):
            # Query screen resolution on host
            try:
                root = tk.Tk()
                W = root.winfo_screenwidth()
                H = root.winfo_screenheight()
                root.destroy()
            except Exception as tk_err:
                print(f"[DemoAgent] Tkinter screen query failed: {tk_err}. Fallback to 1920x1080.")
                W, H = 1920, 1080
            
            # Compute width and height: split the bottom half of the screen
            w = W // 2 - 15
            h = H // 2 - 50
            y = H - h - 60  # Leave space for the Windows taskbar
            
            if thread_id == 1:
                # Customer A: Bottom Left
                x = 0
            else:
                # Customer B: Bottom Right
                x = W - w
                
            # Safely inject window position and size arguments into browser launch
            chrome_args = kwargs.get("args")
            if chrome_args is None:
                chrome_args = []
            else:
                chrome_args = list(chrome_args)  # copy list
            chrome_args.append(f"--window-position={x},{y}")
            chrome_args.append(f"--window-size={w},{h}")
            
            kwargs["args"] = chrome_args
            print(f"[DemoAgent] Laid out Thread {thread_id} at position=({x}, {y}) size=({w}, {h})")

    return original_launch(self, *args, **kwargs)

def patched_new_context(self, *args, **kwargs):
    # Disable default viewport to make page fill the custom window size perfectly
    kwargs["noViewport"] = True
    return original_new_context(self, *args, **kwargs)

def patched_goto(self, url, *args, **kwargs):
    if "3000" in url:
        print(f"[DemoAgent] Delaying 3 seconds before navigating to {url}...")
        time.sleep(3)
    return original_goto(self, url, *args, **kwargs)

async def async_no_op(*args, **kwargs):
    print("[DemoAgent] Intercepted close call: keeping browser/context open.")
    pass

# Apply patches
BrowserType.launch = patched_launch
Browser.new_context = patched_new_context
Page.goto = patched_goto
BrowserContext.close = async_no_op
Browser.close = async_no_op

print("[DemoAgent] Playwright window layout & persistence monkey-patches successfully applied.")

# -----------------------------------------------------------------------------
# REST API SETUP AND ORCHESTRATION
# -----------------------------------------------------------------------------
# Append sibling backend directory to Python path to import existing playwright_runner
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))) + "/backend")

import threading
try:
    import automation.playwright_runner as pr
    
    # Custom dict subclass to block the thread inside run_session_thread
    # before it exits the "with sync_playwright() as p" context.
    class BlockedResultsDict(dict):
        def __setitem__(self, key, value):
            # First set the item so execute_automation_flow receives the notification
            super().__setitem__(key, value)
            
            # Now, sleep forever to keep the browser context active
            print(f"[DemoAgent] Thread {key} finished task. Blocking inside try/catch context to keep browser open...")
            while True:
                time.sleep(1)

    def patched_execute_automation_flow(type_name: str, delay1: str, delay2: str):
        print(f"[DemoAgent] Launching concurrent automation flow via patched runner for {type_name}...")
        
        barrier = threading.Barrier(2)
        results = BlockedResultsDict()  # Use our custom dictionary subclass!
        
        desc1 = f"PHANTOM_LIMIT_DEMO|{type_name.upper()}|{delay1}|1"
        desc2 = f"PHANTOM_LIMIT_DEMO|{type_name.upper()}|{delay2}|2"
        
        t1 = threading.Thread(
            target=pr.run_session_thread,  # Direct target to original run_session_thread
            args=(1, "nguyen_van_a", "Cust@111", "9704002000001", 15000000, desc1, barrier, results),
            daemon=True
        )
        t2 = threading.Thread(
            target=pr.run_session_thread,
            args=(2, "nguyen_van_a", "Cust@111", "9704002000001", 15000000, desc2, barrier, results),
            daemon=True
        )
        
        t1.start()
        t2.start()
        
        # Wait until both threads have populated the results dict
        while len(results) < 2:
            time.sleep(0.5)
            
        # Check results and raise exceptions if any occurred
        for tid, res in results.items():
            if isinstance(res, Exception):
                raise res

    # Apply patched execute_automation_flow to playwright_runner
    pr.execute_automation_flow = patched_execute_automation_flow
    print("[DemoAgent] Playwright runner threading patches successfully applied.")

    from automation.playwright_runner import run_phantom_bad, run_phantom_fix
except ImportError as e:
    print(f"Error importing playwright_runner: {e}")
    sys.exit(1)

app = FastAPI(title="Banking Transaction Management Demo Agent")

class RunRequest(BaseModel):
    demo: str
    mode: str

@app.post("/run")
def run_demo(req: RunRequest):
    print(f"[DemoAgent] Received run request: demo={req.demo}, mode={req.mode}")
    
    if req.demo != "phantom":
        raise HTTPException(status_code=400, detail=f"Unsupported demo scenario: {req.demo}")
        
    if req.mode not in ("bad", "fix"):
        raise HTTPException(status_code=400, detail=f"Unsupported mode: {req.mode}. Must be 'bad' or 'fix'.")
        
    try:
        if req.mode == "bad":
            print("[DemoAgent] Starting Run Bad simulation...")
            run_phantom_bad()
        else:
            print("[DemoAgent] Starting Run Fix simulation...")
            run_phantom_fix()
            
        print("[DemoAgent] Simulation completed successfully!")
        return {"status": "success", "message": f"Successfully completed {req.demo} in {req.mode} mode."}
    except Exception as e:
        print(f"[DemoAgent] Error during execution: {e}")
        raise HTTPException(status_code=500, detail=str(e))
