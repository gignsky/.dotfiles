{ lib, ... }:
{
  # use path relative to the root of the project
  relativeToRoot = lib.path.append ../.;
  scanPaths =
    path:
    builtins.map (f: (path + "/${f}")) (
      builtins.attrNames (
        lib.attrsets.filterAttrs (
          path: _type:
          (_type == "directory") # include directories
          || (
            # FIXME this barfs when child directories don't contain a default.nix
            # example:
            # error: getting status of '/nix/store/mx31x8530b758ap48vbg20qzcakrbc8 (see hosts/common/core/services/default.nix)a-source/hosts/common/core/services/default.nix': No such file or directory
            # I created a blank default.nix in hosts/common/core/services to work around
            (path != "default.nix") # ignore default.nix
            && (lib.strings.hasSuffix ".nix" path) # include .nix files
          )
        ) (builtins.readDir path)
      )
    );
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
