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

DEMO_PASSWORD = "123123"

# ─── Demo data ──────────────────────────────────────────────
BAD_USER = {
    "full_name": "Demo Bad User",
    "username": "demo_bad_user",
    "password": DEMO_PASSWORD,
    "email": "demo_bad@test.com",
    "phone": "0900000001",
}

FIX_USER = {
    "full_name": "Demo Fix User",
    "username": "demo_fix_user",
    "password": DEMO_PASSWORD,
    "email": "demo_fix@test.com",
    "phone": "0900000002",
}


def _run_register_flow(mode: str):
    """
    Playwright automation for register demo.
    mode='bad'  → fills form, intercepts API to call /register_bad, then login → no bank account
    mode='fix'  → fills form, normal /register (sp_RegisterCustomer), then login → has bank account
    """
    user = BAD_USER if mode == "bad" else FIX_USER
    label = "BAD (không Transaction)" if mode == "bad" else "FIX (có Transaction)"

    headless_env = os.getenv("PLAYWRIGHT_HEADLESS")
    if headless_env is not None:
        headless = headless_env.lower() == "true"
    else:
        headless = os.path.exists("/.dockerenv")

    with sync_playwright() as p:
        browser = None
        context = None
        try:
            print(f"[RegisterDemo-{mode}] Launching browser (headless={headless})...")
            browser = p.chromium.launch(headless=headless)
            context = browser.new_context()
            page = context.new_page()

            # ── 1. Navigate to login page, switch to register tab ──
            print(f"[RegisterDemo-{mode}] Navigating to frontend...")
            page.goto(FRONTEND_URL)

            # Click register tab
            reg_tab = page.locator('button:has-text("Đăng ký")')
            reg_tab.wait_for(state="visible", timeout=15000)
            reg_tab.click()
            time.sleep(0.5)

            # ── 2. Fill registration form ──
            print(f"[RegisterDemo-{mode}] Filling registration form for {user['username']}...")

            # Họ tên
            page.locator('input[placeholder="Nguyễn Văn A"]').fill(user["full_name"])
            time.sleep(0.3)

            # Username
            page.locator('input[placeholder="username_123"]').fill(user["username"])
            time.sleep(0.3)

            # Password
            page.locator('input[placeholder="Tối thiểu 6 ký tự"]').fill(user["password"])
            time.sleep(0.3)

            # Email
            page.locator('input[placeholder="email@gmail.com"]').fill(user["email"])
            time.sleep(0.3)

            # Phone
            page.locator('input[placeholder="0901234567"]').fill(user["phone"])
            time.sleep(0.3)

            # ── 3. For BAD mode: intercept API to call /register_bad instead ──
            if mode == "bad":
                def handle_route(route):
                    """Redirect /api/auth/register to /api/auth/register_bad"""
                    print(f"[RegisterDemo-bad] Intercepting API: redirecting to /register_bad")
                    new_url = route.request.url.replace("/api/auth/register", "/api/auth/register_bad")
                    route.continue_(url=new_url)

                page.route("**/api/auth/register", handle_route)

            # ── 4. Click submit ──
            print(f"[RegisterDemo-{mode}] Submitting form ({label})...")
            submit_btn = page.locator('button:has-text("TẠO TÀI KHOẢN")')
            submit_btn.click()

            # Wait for result
            time.sleep(2)

            # Check if registration succeeded (we should see login tab or success message)
            # For BAD mode, the API returns 201 (user IS created, just no bank account)
            print(f"[RegisterDemo-{mode}] Registration submitted. Switching to login...")

            # ── 5. Switch to login tab and login with the new user ──
            login_tab = page.locator('button:has-text("Đăng nhập")')
            login_tab.wait_for(state="visible", timeout=10000)
            login_tab.click()
            time.sleep(0.5)

            # Fill login form
            page.locator('input[placeholder="Nhập username..."]').fill(user["username"])
            time.sleep(0.3)
            page.locator('input[placeholder="Nhập mật khẩu..."]').fill(user["password"])
            time.sleep(0.3)

            # Click login
            page.locator('button:has-text("ĐĂNG NHẬP")').click()
            print(f"[RegisterDemo-{mode}] Logging in as {user['username']}...")

            # Wait for dashboard to load
            time.sleep(3)

            # ── 6. Show result ──
            if mode == "bad":
                print(f"[RegisterDemo-bad] ⚠️ Dashboard loaded — customer should see NO bank accounts (orphan)")
            else:
                print(f"[RegisterDemo-fix] ✅ Dashboard loaded — customer should see bank account")

            print(f"[RegisterDemo-{mode}] Demo completed. Browser will stay open.")

            # Block forever inside the sync_playwright context to keep browser alive
            while True:
                time.sleep(1)

        except Exception as e:
            import traceback
            print(f"[RegisterDemo-{mode}] Error: {e}")
            traceback.print_exc()
            # Still keep browser open on error so user can see state
            while True:
                time.sleep(1)


def run_register_bad():
    print("[Automation] Starting register BAD demo...")
    t = threading.Thread(target=_run_register_flow, args=("bad",), daemon=True)
    t.start()
    # Wait enough time for the flow to complete (register + login + dashboard load)
    time.sleep(15)
    print("[Automation] Register BAD demo launched, browser is open.")


def run_register_fix():
    print("[Automation] Starting register FIX demo...")
    t = threading.Thread(target=_run_register_flow, args=("fix",), daemon=True)
    t.start()
    time.sleep(15)
    print("[Automation] Register FIX demo launched, browser is open.")

