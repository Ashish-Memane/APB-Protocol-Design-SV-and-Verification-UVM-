#!/usr/bin/env python3
# ==================================================================================
# File Name: dv_regress.py
# Description: Automated Python Regression Runner & Tracker for APB Subsystem Test Plan
# ==================================================================================

import os
import sys
import subprocess
import time
import random

# Color configurations for clean MobaXterm terminal logging
GREEN = "\033[92m"
RED   = "\033[91m"
BLUE  = "\033[94m"
BOLD  = "\033[1m"
RESET = "\033[0m"

# Map of Testcase IDs to actual UVM Class Test Names defined in your plan 
TEST_SUITE = {
    "TC_01": "apb_reset_test",
    "TC_02": "apb_write_gpio_test",
    "TC_03": "apb_read_gpio_test",
    "TC_04": "apb_write_uart_test",
    "TC_05": "apb_read_uart_test",
    "TC_06": "apb_write_spi_test",
    "TC_07": "apb_read_spi_test",
    "TC_08": "uart_tx_test",
    "TC_09": "uart_rx_test",
    "TC_10": "spi_transfer_test",
    "TC_11": "gpio_direction_test",
    "TC_12": "invalid_address_test",
    "TC_13": "back_to_back_write_test",
    "TC_14": "back_to_back_read_test",
    "TC_15": "mixed_read_write_test",
    "TC_16": "random_apb_write_test",
    "TC_17": "random_apb_read_test",
    "TC_18": "random_apb_rw_test",
    "TC_19": "uart_spi_gpio_mix_test",
    "TC_20": "stress_test"
}

def run_test(tc_id, uvm_test_name, seed):
    """Executes a single testcase by calling the local Makefile via subprocess."""
    log_name = f"{tc_id}_{uvm_test_name}_seed_{seed}.log"
    print(f"{BLUE}[RUNNING]{RESET} {tc_id:5s} : {uvm_test_name:<25s} (Seed: {seed})")
    
    # Update this command array to match your exact Makefile variables
    # e.g., make run TESTNAME=apb_reset_test SEED=12345 LOGFILE=TC_01_apb_reset_test.log
    cmd = [
        "make", "run",
        f"TESTNAME={uvm_test_name}",
        f"SEED={seed}",
        f"LOGFILE={log_name}"
    ]
    
    start_time = time.time()
    try:
        # Run simulation in background, saving output to the discrete log file
        result = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True, timeout=300)
        elapsed = time.time() - start_time
        
        # Evaluate standard log verification vectors to check status
        if os.path.exists(log_name):
            with open(log_name, 'r') as f:
                content = f.read()
                if "UVM_ERROR :" in content or "UVM_FATAL :" in content or "Errors: " in content:
                    if "UVM_ERROR :    0" in content and "UVM_FATAL :    0" in content:
                        return "PASSED", elapsed, log_name
                    else:
                        return "FAILED", elapsed, log_name
                        
        if result.returncode == 0:
            return "PASSED", elapsed, log_name
        return "FAILED", elapsed, log_name
        
    except subprocess.TimeoutExpired:
        return "TIMEOUT", 300.0, log_name
    except Exception as e:
        return f"CRASHED ({str(e)})", 0.0, log_name

def main():
    print(f"{BOLD}{BLUE}==================================================================={RESET}")
    print(f"{BOLD}{BLUE}     APB Subsystem DV Automation Regression Engine v2026.1         {RESET}")
    print(f"{BOLD}{BLUE}==================================================================={RESET}")
    
    # Ensure work directory is built once before spawning parallel iterations
    print(f"{BLUE}[PRE-COMPILE] Refreshing local design database libraries...{RESET}")
    subprocess.run(["make", "compile"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    
    results = {}
    passed_count = 0
    
    for tc_id, uvm_test in TEST_SUITE.items():
        # Generate a distinct random seed for constrained-random coverage variability [cite: 52]
        seed = random.randint(1, 999999)
        status, duration, log_file = run_test(tc_id, uvm_test, seed)
        
        results[tc_id] = {"name": uvm_test, "status": status, "time": duration, "log": log_file}
        
        if status == "PASSED":
            passed_count += 1
            print(f"{GREEN}[PASSED]{RESET}  In {duration:.2f}s\n")
        else:
            print(f"{RED}[{status}]{RESET} Check {log_file} for diagnostics\n")
            
    # Print Terminal Regression Status Dashboard Matrix
    print(f"\n{BOLD}==================================================================={RESET}")
    print(f"{BOLD}                    REGRESSION SUMMARY REPORT                      {RESET}")
    print(f"==================================================================={#}")
    for tc_id, data in results.items():
        color = GREEN if data["status"] == "PASSED" else RED
        print(f" {tc_id:5s} | {data['name']:<25s} | {color}{data['status']:<8s}{RESET} | Run Time: {data['time']:6.2f}s")
    print(f"==================================================================={RESET}")
    
    success_rate = (passed_count / len(TEST_SUITE)) * 100
    color_rate = GREEN if success_rate >= 95.0 else RED [cite: 304]
    print(f"{BOLD}Total Progress Achieved: {passed_count}/{len(TEST_SUITE)} Tests Passed ({color_rate}{success_rate:.1f}%{RESET}){RESET}\n")

if __name__ == "__main__":
    main()
