#!/usr/bin/env python3
# ==================================================================================
# File Name: parse_coverage.py
# Description: Inline UCDB coverage collector parser for restricted terminal displays
# ==================================================================================

import os
import subprocess

GREEN = "\033[92m"
RED   = "\033[91m"
BOLD  = "\033[1m"
RESET = "\033[0m"

def extract_terminal_coverage():
    """Generates an intermediate summary file and extracts coverage metrics."""
    temp_report = "terminal_cov_raw.txt"
    
    # 1. Instruct the vcover utility to merge individual runs into a single summary layout [cite: 48]
    # Assumes your Makefile/sim saves coverage to 'apb_cov.ucdb'
    cmd = "vcover report -cvg -details -codeAll -assert -text -file " + temp_report
    
    if not os.path.exists("apb_cov.ucdb") and not os.path.exists("work"):
        print(f"{RED}[ERROR] No simulation database coverage metrics located. Run regressions first.{RESET}")
        return
        
    subprocess.run(cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    
    if not os.path.exists(temp_report):
        print(f"{RED}[ERROR] Unable to capture database summary indices.{RESET}")
        return

    # 2. Extract metrics directly to the screen terminal buffer
    print(f"\n{BOLD}==================================================================={RESET}")
    print(f"{BOLD}           EXTRACTED FUNCTIONAL SIGN-OFF COVERAGE MATRIX           {RESET}")
    print(f"==================================================================={RESET}")
    
    with open(temp_report, 'r') as f:
        lines = f.readlines()
        for line in lines:
            # Filter and print relevant summary metrics [cite: 304, 326]
            if any(metric in line for metric in ["Total Coverage", "Covergroup", "Assertion", "Statement", "FSM", "Toggle"]):
                if "TOTAL" in line or "Total" in line:
                    print(f"{BOLD}{GREEN}{line.strip()}{RESET}")
                else:
                    print(f"  {line.strip()}")
                    
    print(f"==================================================================={RESET}")
    
    # Cleanup intermediate plain text files safely
    try:
        os.remove(temp_report)
    except OSError:
        pass

if __name__ == "__main__":
    extract_terminal_coverage()
