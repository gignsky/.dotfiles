{ lib, ... }:
{
  # use path relative to the root of the project
  relativeToRoot = lib.path.append ../.;
  # ┌─────────────────────────────────────────────────────────────┐
  # │ FUNCTION: scanNuResources                                   │
  # └─────────────────────────────────────────────────────────────┘
  # DESCRIPTION: Reads all regular files ending in '.nu' from a given directory
  # and concatenates their content into a single, newline-separated string.
  # This output is suitable for direct interpolation into the NuShell extraConfig.
  #
  # INPUTS:
  # - path: <path> | The absolute or relative path to the directory containing .nu scripts.
  #
  # OUTPUTS:
  # - <string> | A single string containing the contents of all found .nu files,
  #              separated by two newline characters ("\n\n").
  #
  scanPathsNuShell =
    path:
    let
      # Read the directory contents (returns { filename = file_type; })
      dirContents = builtins.readDir path;

      # Filter keys (filenames) to only keep regular files ending in .nu
      nuFileNames = lib.filter (name: lib.hasSuffix ".nu" name) (lib.attrNames dirContents);

      # Map over the filenames to read the content of each file
      fileContentList = lib.map (name: builtins.readFile (path + "/${name}")) nuFileNames;
    in
    # Concatenate the list of file contents into a single string.
    lib.concatStringsSep "\n\n" fileContentList;
}
