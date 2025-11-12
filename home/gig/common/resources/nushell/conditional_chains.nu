# run_on_success.nu
# A function to execute an arbitrary number of commands in a chain.
# The chain halts immediately if any command exits with a non-zero code.

def conditional-chain [
    commands: list<any>    # A list containing all command blocks to execute
] {
    let success_count = 0
    let failure_code = 0

    # Iterate over the provided list of command blocks
    for command in $commands {
        # Use 'try' to execute the command block and capture its output and exit code.
        let result = (try {
            # 'do' is necessary to execute the block content here.
            do $command
        })

        # Check the captured exit code.
        if $result.exit_code != 0 {
            # If the command failed, halt the entire function.
            let failure_code = $result.exit_code
            print $"[ERROR]: Command failed with exit code ({$failure_code}). Halting chain immediately."

            # Ensure the function itself exits with the failing code.
            error make {
                msg: "Conditional command chain halted due to an upstream failure."
                exit_code: $failure_code
            }
            return
        }
        let success_count = ($success_count + 1)
    }

    # If the loop completes without returning, all commands succeeded.
    print $"All ($success_count) commands in the chain succeeded."
}

alias "cc" = conditional-chain

# --- Example Usage for Multiple Commands ---
# 1. Source the file: source run_on_success.nu

# 2. Chain 3 commands: The 'false' command fails, halting the chain before 'echo done'.
# conditional-chain [
#     { echo "Attempting task one..." }
#     { nix flake check }
#     { false }
#     { gcam "added gomono nerd font" }
#     { echo "This line will not be reached." }
# ]
# 3. Successful Chain:
# conditional-chain [
#     { echo "Successful run of first task" }
#     { sleep 100ms }
#     { echo "Successful run of second task" }
# ]
