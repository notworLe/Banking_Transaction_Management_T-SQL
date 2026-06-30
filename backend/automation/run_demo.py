import sys
import os

# Ensure backend root is in PYTHONPATH
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from automation.playwright_runner import run_phantom_bad, run_phantom_fix

def main():
    if len(sys.argv) < 2:
        print("Usage: python run_demo.py [bad|fix]")
        sys.exit(1)
        
    mode = sys.argv[1].lower()
    if mode == "bad":
        run_phantom_bad()
    elif mode == "fix":
        run_phantom_fix()
    else:
        print(f"Error: Unknown mode '{mode}'. Must be 'bad' or 'fix'.")
        sys.exit(1)

if __name__ == "__main__":
    main()
