"""
Also run this to check your preprocess.py:
  python check_preprocess.py
"""
import sys
sys.path.insert(0, '.')

# Read preprocess.py directly
with open("app/preprocess.py") as f:
    print("=== app/preprocess.py ===")
    print(f.read())
