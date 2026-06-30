import os
import time
import threading
from playwright.sync_api import sync_playwright

FRONTEND_URL = os.getenv("FRONTEND_URL")
if not FRONTEND_URL:
    if os.path.exists("/.dockerenv"):
        FRONTEND_URL = "http://frontend:3000"
    else:
        FRONTEND_URL = "http://localhost:3000"

def run_session_thread(thread_id, username, password, to_account, amount, description, barrier, results):
    headless_env = os.getenv("PLAYWRIGHT_HEADLESS")
    if headless_env is not None:
        headless = headless_env.lower() == "true"
    else:
        headless = os.path.exists("/.dockerenv")
    
    with sync_playwright() as p:
        context = None
        browser = None
        try:
            print(f"[Thread {thread_id}] Launching browser (headless={headless})...")
            browser = p.chromium.launch(headless=headless)
            
            context = browser.new_context()
            page = context.new_page()
            
            # Print console messages for debug
            page.on("console", lambda msg: print(f"[Browser Console - {username} - Thread {thread_id}] {msg.text}"))
            
            # Navigation & Login
            print(f"[Thread {thread_id}] Navigating to login...")
            page.goto(FRONTEND_URL)
            
            username_input = page.locator('input[placeholder="Nhập username..."]')
            username_input.wait_for(state="visible", timeout=15000)
            username_input.fill(username)
            
            password_input = page.locator('input[placeholder="Nhập mật khẩu..."]')
            password_input.wait_for(state="visible", timeout=15000)
            password_input.fill(password)
            
            login_button = page.locator('button.btn-primary')
            print(f"[Thread {thread_id}] Logging in...")
            login_button.click()
            
            # Wait for login success
            badge = page.locator(f'.sidebar-logo div:has-text("@{username}")')
            badge.wait_for(state="visible", timeout=15000)
            
            # Go to transfer page
            transfer_button = page.locator('button.nav-item:has-text("Chuyển tiền")')
            transfer_button.wait_for(state="visible", timeout=15000)
            print(f"[Thread {thread_id}] Navigating to Transfer page...")
            transfer_button.click()
            
            # Wait for header
            transfer_header = page.locator('h2:has-text("CHUYỂN TIỀN")')
            transfer_header.wait_for(state="visible", timeout=15000)
            
            # Fill form
            print(f"[Thread {thread_id}] Filling transfer form...")
            
            # Select From Account (Wait for options to load)
            select_elem = page.locator('select.form-control')
            select_elem.wait_for(state="visible", timeout=15000)
            
            option = page.locator('select.form-control option').filter(has_text="9704001000001")
            option.wait_for(state="attached", timeout=15000)
            from_acc_val = option.get_attribute("value")
            page.select_option('select.form-control', from_acc_val)
            
            # Fill To Account
            to_acc_input = page.locator('input[placeholder="Nhập số tài khoản..."]')
            to_acc_input.wait_for(state="visible", timeout=15000)
            to_acc_input.fill(to_account)
            
            # Fill Amount
            amount_input = page.locator('input[type="number"]')
            amount_input.wait_for(state="visible", timeout=15000)
            amount_input.fill(str(amount))
            
            # Fill Description
            desc_input = page.locator('input[placeholder="Nội dung..."]')
            desc_input.wait_for(state="visible", timeout=15000)
            desc_input.fill(description)
            
            print(f"[Thread {thread_id}] Form filled completely. Waiting at barrier...")
            
            # Wait at barrier
            barrier.wait()
            
            # Click submit simultaneously!
            print(f"[Thread {thread_id}] Click transfer submit!")
            
            # Use expect_response to wait for the transfer API response
            with page.expect_response("**/api/customer/transactions/transfer", timeout=20000) as response_info:
                page.locator('button[type="submit"]').click()
            
            response = response_info.value
            try:
                resp_text = response.text()
            except Exception as re_err:
                resp_text = f"Failed to get text: {re_err}"
            print(f"[Thread {thread_id}] API Response status: {response.status}")
            print(f"[Thread {thread_id}] API Response body: {ascii(resp_text)}")
            print(f"[Thread {thread_id}] Sent Payload: FromAccount={from_acc_val}, ToAccount={to_account}, Amount={amount}, Description={ascii(description)}")
            
            # Wait 2 seconds to make sure toast or other client-side updates complete before closing
            time.sleep(2)
            results[thread_id] = True
            
        except Exception as e:
            import traceback
            print(f"[Thread {thread_id}] Error in automation: {e}")
            traceback.print_exc()
            results[thread_id] = e
        finally:
            try:
                if context:
                    context.close()
                if browser:
                    browser.close()
            except Exception:
                pass

def execute_automation_flow(type_name: str, delay1: str, delay2: str):
    print(f"[Playwright] Launching concurrent automation flow for {type_name}...")
    
    barrier = threading.Barrier(2)
    results = {}
    
    # Session 1: slow (runs with delay1)
    desc1 = f"PHANTOM_LIMIT_DEMO|{type_name.upper()}|{delay1}|1"
    # Session 2: fast (runs with delay2)
    desc2 = f"PHANTOM_LIMIT_DEMO|{type_name.upper()}|{delay2}|2"
    
    t1 = threading.Thread(
        target=run_session_thread,
        args=(1, "nguyen_van_a", "Cust@111", "9704002000001", 15000000, desc1, barrier, results)
    )
    t2 = threading.Thread(
        target=run_session_thread,
        args=(2, "nguyen_van_a", "Cust@111", "9704002000001", 15000000, desc2, barrier, results)
    )
    
    t1.start()
    t2.start()
    
    t1.join()
    t2.join()
    
    # Check results
    for tid, res in results.items():
        if isinstance(res, Exception):
            raise res

def run_phantom_bad(delay1="00:00:08", delay2="00:00:02"):
    print(f"[Automation] Starting run_phantom_bad() simulation with delays {delay1}, {delay2}...")
    execute_automation_flow("bad", delay1, delay2)

def run_phantom_fix(delay1="00:00:08", delay2="00:00:02"):
    print(f"[Automation] Starting run_phantom_fix() simulation with delays {delay1}, {delay2}...")
    execute_automation_flow("fix", delay1, delay2)
