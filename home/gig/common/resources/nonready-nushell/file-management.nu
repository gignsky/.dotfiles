# # ┌──────────────────────────────────────────────────┐
# # │ Shadowed Commands for Directory Pre-creation (cp/mv) │
# # │ These functions are defined to automatically perform │
# # │ 'mkdir -p' on the destination path prior to operation. │
# # └──────────────────────────────────────────────────┘
#
# # This function shadows the default 'cp' command.
# def cp [from: path, to: path] {
#   # Extract the parent path of the target file using 'path dirname'.
#   let dest_dir = (
#     $to | path dirname
#   )
#
#   # Create the directory (and any necessary parents).
#   mkdir $dest_dir
#
#   # Call the original, built-in 'cp' command using '^cp'.
#   ^cp -rv $from $to
# }
#
# # This function shadows the default 'mv' command.
# def mv [from: path, to: path] {
#   let dest_dir = (
#     $to | path dirname
#   )
#
#   mkdir $dest_dir
#
#   # Call the original, built-in 'mv' command.
#   ^mv -v $from $to
# }

# file-management.nu
# Provides 'supercopy' and 'supermove' commands that
# automatically create destination directories if they don't exist,
# wrapping the core 'cp' and 'mv' utilities.
# These commands preserve the argument and help documentation
# and provide enhanced directory creation capabilities.

# A helper function to determine the directory path that needs to exist
# for a given destination. If the destination path ends with a path separator,
# it's treated as a directory path and returned as-is.
# Otherwise, its parent directory is returned.
def get-dir-to-create [destination: string] {
    if ($destination | str ends-with '/' or ($destination | str ends-with '\')) {
        $destination
    } else {
        $destination | path dirname
    }
}

# A 'super' copy command that automatically creates the destination directory path.
# It wraps the built-in 'cp' command, preserving its arguments and help documentation.
export def --wrapped supercopy [
    ...rest # All arguments for the underlying 'cp' command
] {
    # Passthrough --help request to the original command
    if ($rest | contains '--help') {
        ^cp --help
        return
    }

    # If not enough arguments, let the original command handle the error
    if ($rest | length) < 2 {
        ^cp ...$rest
        return
    }

    # The destination is always the last argument for cp
    let destination = ($rest | last)

    # Determine which directory needs to be created
    let dir_to_create = (get-dir-to-create $destination)

    # Create the directory if it doesn't exist
    # Use try..catch in case of permission errors etc.
    try {
        if not ($dir_to_create | path exists) {
            mkdir -v $dir_to_create
            # Optional: print a message
            # print -e $"Created directory : ($dir_to_create)"
        }
    } catch {
        print -e $"Error creating directory: ($dir_to_create). See error below."
        print -e $in
        # Allow the operation to continue, cp/mv will likely fail and give a better error
    }

    # Execute the original cp command with all arguments
    ^cp ...$rest
}

# A 'super' move command that automatically creates the destination directory path.
# It wraps the built-in 'mv' command, preserving its arguments and help documentation.
export def --wrapped supermove [
    ...rest # All arguments for the underlying 'mv' command
] {
    # Passthrough --help request to the original command
    if ($rest | contains '--help') {
        ^mv --help
        return
    }

    # If not enough arguments, let the original command handle the error
    if ($rest | length) < 2 {
        ^mv ...$rest
        return
    }

    # The destination is always the last argument for mv
    let destination = ($rest | last)

    # Determine which directory needs to be created
    let dir_to_create = (get-dir-to-create $destination)

    # Create the directory if it doesn't exist
    try {
        if not ($dir_to_create | path exists) {
            mkdir -v $dir_to_create
        }
    } catch {
        print -e $"Error creating directory: ($dir_to_create). See error below."
        print -e $in
    }

    # Execute the original mv command with all arguments
    ^mv ...$rest
}
