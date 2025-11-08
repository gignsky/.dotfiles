# ┌──────────────────────────────────────────────────┐
# │ Shadowed Commands for Directory Pre-creation (cp/mv) │
# │ These functions are defined to automatically perform │
# │ 'mkdir -p' on the destination path prior to operation. │
# └──────────────────────────────────────────────────┘

# This function shadows the default 'cp' command.
def cp [from: path, to: path] {
  # Extract the parent path of the target file using 'path dirname'.
  let dest_dir = (
    $to | path dirname
  )

  # Create the directory (and any necessary parents).
  mkdir $dest_dir

  # Call the original, built-in 'cp' command using 'core cp'.
  core cp $from $to
}

# This function shadows the default 'mv' command.
def mv [from: path, to: path] {
  let dest_dir = (
    $to | path dirname
  )
  
  mkdir $dest_dir
  
  # Call the original, built-in 'mv' command.
  core mv $from $to
}
