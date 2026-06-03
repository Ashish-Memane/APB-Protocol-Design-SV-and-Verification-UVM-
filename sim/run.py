import subprocess
import sys
import os
import pandas as pd

# ==============================================================================
# 1. Load Configuration and Testcases from Excel
# ==============================================================================
try:
    # Read the excel sheet
    df = pd.read_excel('dir_info.xlsx', engine='openpyxl')

    # Clean up column names (strip whitespace)
    df.columns = df.columns.str.strip()

    # 1a. Build the environment config dictionary (from 'key' and 'value' columns)
    # We drop rows where 'key' is NaN for this mapping
    config_df = df.dropna(subset=['key'])
    config = dict(zip(config_df['key'].str.strip(), config_df['value']))

    # 1b. Extract the testcases list (from 'testcase_name' column)
    # We filter out empty/NaN rows to get a clean list of valid test names
    testcases = df['testcase_name'].dropna().str.strip().tolist()

except Exception as e:
    print(f"❌ Error parsing 'dir_info.xlsx': {e}")
    sys.exit(1)

# Assign environment values from the config
FSDB_PATH = "/home/cad/eda/SYNOPSYS/VERDI_2022/verdi/T-2022.06-SP1/share/PLI/VCS/LINUX64"

RTL   = config.get("RTL", "../rtl/* ../interface/*")
SVTB1 = config.get("SVTB1", "../tb/top.sv")
SVTB2 = config.get("SVTB2", "../test/apb_protocol_pkg.sv")
INC   = config.get("INC", "")

# ==============================================================================
# 2. Automation Functions
# ==============================================================================

def clean_workspace():
    """ Cleans up old simulation files to ensure a fresh run """
    print("\n🧹 Cleaning old logs, waveforms, and coverage directories...")
    # Clean wildcards using shell execution for simplicity
    subprocess.run("rm -rf simv* csrc* *.log *.fsdb *.vdb urgReport* merged_dir/", shell=True)
    print("✅ Workspace cleaned.")


def sv_cmp_VCS():
    """ Compile the codebase using VCS """
    print("\n🚀 Starting VCS Compilation...")
    command = (
        f"vcs -l vcs.log -timescale=1ns/1ps -sverilog -ntb_opts uvm "
        f"-debug_access+all -full64 -kdb -lca -P {FSDB_PATH}/novas.tab "
        f"{FSDB_PATH}/pli.a {RTL} {INC} {SVTB2} {SVTB1}"
    )
    print(f"📁 Running: {command}\n")
    subprocess.run(command, shell=True, check=True)
    print("✅ Compilation Successful.")


def run_single_sim(test_name, index):
    """ Runs an individual simulation and creates a local coverage report """
    print(f"\n🏃 [Test {index}] Running Simulation for: {test_name}...")

    # Create unique wave and coverage directory names based on index or name
    wave_file = f"wave_{index}.fsdb"
    cov_dir = f"mem_cov_{index}"
    urg_report = f"urgReport_{index}"

    sim_command = (
        f"./simv -a vcs.log +fsdbfile+{wave_file} -cm_dir ./{cov_dir} "
        f"+ntb_random_seed_automatic +UVM_TESTNAME={test_name}"
    )
    urg_command = f"urg -dir {cov_dir}.vdb -format both -report {urg_report}"

    # Run simulation executable
    subprocess.run(sim_command, shell=True, check=True)
    # Run individual coverage generation
    subprocess.run(urg_command, shell=True, check=True)
    print(f"✅ Test {index} ({test_name}) passed simulation execution.")


def run_regression():
    """ Loops through all tests found in Excel and merges coverage at the end """
    if not testcases:
        print("⚠ No testcases found in the 'testcase_name' column of your Excel file!")
        return

    print(f"\n📋 Found {len(testcases)} testcases for Regression Suite:")
    for idx, test in enumerate(testcases, 1):
        print(f"  {idx}. {test}")

    # Step 1: Prep environment
    clean_workspace()
    sv_cmp_VCS()

    # Step 2: Run all tests sequentially
    print("\n⚡ Kicking off Regression Test Runs...")
    for idx, test_name in enumerate(testcases, 1):
        run_single_sim(test_name, idx)

    # Step 3: Merge all coverage data collected
    print("\n📊 Merging Code Coverage for all testcases...")
    # Find all generated .vdb directories dynamically
    all_vdb_dirs = " ".join([f"mem_cov_{i}.vdb" for i in range(1, len(testcases) + 1)])

    merge_command = f"urg -dir {all_vdb_dirs} -dbname merged_dir/merged_test -format both -report urgReport"
    subprocess.run(merge_command, shell=True, check=True)
    print("\n✅ Regression Completed! Merged report generated in './urgReport/'")

# ==============================================================================
# 3. Main Interface Execution Control
# ==============================================================================
if __name__ == "__main__":
    print("=============================================")
    print("   VCS/Verdi UVM Automation Framework       ")
    print("=============================================")
    print("Select an option:")
    print("1. Run Single Test (Manual input)")
    print("2. Run Full Regression (All tests from Excel)")
    print("3. Clean Workspace")

    choice = input("\nEnter choice (1/2/3): ").strip()

    try:
        if choice == "1":
            test_class = input("Enter the UVM test case name: ").strip()
            if test_class:
                clean_workspace()
                sv_cmp_VCS()
                run_single_sim(test_class, 1)
        elif choice == "2":
            run_regression()
        elif choice == "3":
            clean_workspace()
        else:
            print("❌ Invalid Choice. Exiting.")

    except subprocess.CalledProcessError:
        print("\n❌ Automation stopped: A tool command returned an execution error.")
        sys.exit(1)
