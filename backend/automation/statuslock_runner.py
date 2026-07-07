import os
import time
import threading
from playwright.sync_api import sync_playwright
import urllib.request
import json

FRONTEND_URL = os.getenv("FRONTEND_URL")
if not FRONTEND_URL:
    if os.path.exists("/.dockerenv"):
        FRONTEND_URL = "http://frontend:3000"
    else:
        FRONTEND_URL = "http://localhost:3000"

# Dùng class để chia sẻ kết quả giữa các threads giống phantom_runner
class BlockedResultsDict(dict):
    pass

def run_customer_transfer(thread_id, username, password, to_account, amount, description, is_fix, barrier, results):
    """T1 (Customer) thực hiện chuyển tiền"""
    headless_env = os.getenv("PLAYWRIGHT_HEADLESS")
    headless = headless_env.lower() == "true" if headless_env is not None else os.path.exists("/.dockerenv")
    
    with sync_playwright() as p:
        context = None
        browser = None
        try:
            print(f"[StatusLock-T1] Launching customer browser...")
            browser = p.chromium.launch(headless=headless)
            context = browser.new_context()
            page = context.new_page()
            
            # Navigate & Login
            page.goto(FRONTEND_URL)
            time.sleep(1)
            page.locator('input[placeholder="Nhập username..."]').fill(username)
            page.locator('input[placeholder="Nhập mật khẩu..."]').fill(password)
            time.sleep(1)
            page.locator('button.btn-primary:has-text("ĐĂNG NHẬP")').click()
            page.locator(f'.sidebar-logo div:has-text("@{username}")').wait_for(state="visible", timeout=15000)
            
            time.sleep(9)
            # Go to transfer page
            page.locator('button.nav-item:has-text("Chuyển tiền")').click()
            page.locator('h2:has-text("CHUYỂN TIỀN")').wait_for(state="visible")
            
            time.sleep(3)
            
            # Intercept Transfer API
            def handle_route(route):
                print(f"[StatusLock-T1] Intercepting transfer request. Routing to demo endpoint...")
                # We overwrite the post data to hit our demo endpoint
                post_data = {"is_fix": is_fix}
                new_url = route.request.url.replace("/api/customer/transactions/transfer", "/api/demo/statuslock_transfer")
                route.continue_(url=new_url, post_data=json.dumps(post_data).encode("utf-8"))
                
            page.route("**/api/customer/transactions/transfer", handle_route)
            
            # Fill form
            page.locator('select.form-control option').filter(has_text="9704001000001").wait_for(state="attached", timeout=15000)
            page.select_option('select.form-control', value=page.locator('select.form-control option').filter(has_text="9704001000001").get_attribute("value"))
            page.locator('input[placeholder="Nhập số tài khoản..."]').fill(to_account)
            page.locator('input[type="number"]').fill(str(amount))
            page.locator('input[placeholder="Nội dung..."]').fill(description)
            
            print(f"[StatusLock-T1] Form filled. Waiting at barrier...")
            barrier.wait()
            
            # Click submit
            print(f"[StatusLock-T1] Submitting transfer!")
            with page.expect_response("**/api/demo/statuslock_transfer", timeout=30000) as response_info:
                page.locator('button[type="submit"]').click()
                
            res = response_info.value
            print(f"[StatusLock-T1] Transfer API returned status {res.status}")
            
            results[thread_id] = True
            
            # Giữ browser mở để user xem
            print(f"[StatusLock-T1] Finished. Blocking thread to keep browser open...")
            while True:
                time.sleep(1)
                
        except Exception as e:
            import traceback
            print(f"[StatusLock-T1] Error: {str(e).encode('ascii', 'ignore').decode('ascii')}")
            traceback.print_exc()
            results[thread_id] = e
            while True:
                time.sleep(1)

def run_banker_lock(thread_id, username, password, target_username, is_fix, barrier, results):
    """T2 (Banker) khóa tài khoản"""
    headless_env = os.getenv("PLAYWRIGHT_HEADLESS")
    headless = headless_env.lower() == "true" if headless_env is not None else os.path.exists("/.dockerenv")
    
    with sync_playwright() as p:
        context = None
        browser = None
        try:
            print(f"[StatusLock-T2] Launching banker browser...")
            browser = p.chromium.launch(headless=headless)
            context = browser.new_context()
            page = context.new_page()
            
            # Navigate & Login
            page.goto(FRONTEND_URL)
            time.sleep(1)
            page.locator('input[placeholder="Nhập username..."]').fill(username)
            page.locator('input[placeholder="Nhập mật khẩu..."]').fill(password)
            time.sleep(1)
            page.locator('button.btn-primary:has-text("ĐĂNG NHẬP")').click()
            page.locator(f'.sidebar-logo div:has-text("@{username}")').wait_for(state="visible", timeout=15000)
            
            time.sleep(2)
            # Go to Quản lý tài khoản (Banker Dashboard)
            page.locator('button.nav-item:has-text("Tài khoản")').click()
            page.locator('h3:has-text("Quản lý Tài khoản")').wait_for(state="visible")
            
            time.sleep(2)
            
            # Wait for accounts to load
            page.locator('td:has-text("9704001000001")').wait_for(state="visible", timeout=15000)
            
            # Find the Lock button for this account
            row = page.locator('tr').filter(has_text="9704001000001")
            lock_button = row.locator('button.btn-magenta:has-text("KHÓA")')
            lock_button.wait_for(state="visible")
            
            # Intercept Lock API
            def handle_route(route):
                print(f"[StatusLock-T2] Intercepting lock request. Routing to demo endpoint...")
                # We overwrite the post data to hit our demo endpoint
                post_data = {"is_fix": is_fix}
                new_url = route.request.url.replace("/status", "").replace("/api/banker/accounts/", "/api/demo/statuslock_lock/")
                route.continue_(url=new_url, post_data=json.dumps(post_data).encode("utf-8"), method="PATCH")
                
            page.route("**/api/banker/accounts/*/status", handle_route)
            
            print(f"[StatusLock-T2] Ready. Waiting at barrier...")
            barrier.wait()
            
            # The Banker should click KHÓA shortly after the customer clicks Transfer. 
            # In demo_runner, T2 starts 2 seconds after T1. Playwright clicking might take some ms.
            # We add a 2 second sleep before clicking to match the T-SQL timing.
            time.sleep(2)
            
            print(f"[StatusLock-T2] Clicking KHÓA account!")
            with page.expect_response("**/api/demo/statuslock_lock/*", timeout=30000) as response_info:
                lock_button.click()
                
            res = response_info.value
            print(f"[StatusLock-T2] Lock API returned status {res.status}")
            
            results[thread_id] = True
            
            # Giữ browser mở
            print(f"[StatusLock-T2] Finished. Blocking thread to keep browser open...")
            while True:
                time.sleep(1)
                
        except Exception as e:
            import traceback
            print(f"[StatusLock-T2] Error: {str(e).encode('ascii', 'ignore').decode('ascii')}")
            traceback.print_exc()
            results[thread_id] = e
            while True:
                time.sleep(1)


def execute_statuslock_flow(mode: str):
    print(f"[Playwright] Launching concurrent automation flow for statuslock {mode}...")
    
    is_fix = (mode == "fix")
    barrier = threading.Barrier(2)
    results = BlockedResultsDict()
    
    # T1: Customer transferring money
    t1 = threading.Thread(
        target=run_customer_transfer,
        args=(1, "nguyen_van_a", "Cust@111", "9704002000001", 15000000, f"STATUSLOCK_DEMO|{mode.upper()}|Transfer", is_fix, barrier, results),
        daemon=True
    )
    
    # T2: Banker locking the account
    t2 = threading.Thread(
        target=run_banker_lock,
        args=(2, "banker_nam", "Banker@123", "nguyen_van_a", is_fix, barrier, results),
        daemon=True
    )
    
    t1.start()
    t2.start()
    
    # Wait until both threads have completed their main flow and populated the results dict
    while len(results) < 2:
        time.sleep(0.5)
        
    for tid, res in results.items():
        if isinstance(res, Exception):
            raise res

def run_statuslock_bad():
    print("[Automation] Starting run_statuslock_bad() simulation...")
    execute_statuslock_flow("bad")

def run_statuslock_fix():
    print("[Automation] Starting run_statuslock_fix() simulation...")
    execute_statuslock_flow("fix")
