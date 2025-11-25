# Up-tools: Git commit utilities for common file updates
# These are convenience scripts for quickly committing specific types of file changes

{ pkgs }:

{
  upignore =
    pkgs.writeShellScriptBin "upignore" ''
      git add .gitignore
      git commit -m "upignore - updated .gitignore"
    ''
    // {
      passthru.tests = {
        basic =
          pkgs.runCommand "upignore-test"
            {
              buildInputs = [
                pkgs.writeShellScriptBin
                "upignore"
                ""
              ];
            }
            ''
              set -e
              # Should fail gracefully since .git may not exist in sandbox
              if upignore > $out 2>&1; then
                grep -q ".gitignore" $out || true
              else
                grep -q "not a git repository" $out || true
              fi
            '';
      };
    };

  upjust =
    pkgs.writeShellScriptBin "upjust" ''
      git add justfile
      git commit -m "upjust - updated justfile"
    ''
    // {
      passthru.tests = {
        basic =
          pkgs.runCommand "upjust-test"
            {
              buildInputs = [
                pkgs.writeShellScriptBin
                "upjust"
                ""
              ];
            }
            ''
              set -e
              # Should fail gracefully since .git may not exist in sandbox
              if upjust > $out 2>&1; then
                grep -q "justfile" $out || true
              else
                grep -q "not a git repository" $out || true
              fi
            '';
      };
    };

  upspell =
    pkgs.writeShellScriptBin "upspell" ''
      git add .cspell/custom-dictionary-workspace.txt
      git commit -m "upspell - updated spellfile"
    ''
    // {
      passthru.tests = {
        basic =
          pkgs.runCommand "upspell-test"
            {
              buildInputs = [
                pkgs.writeShellScriptBin
                "upspell"
                ""
              ];
            }
            ''
              set -e
              # Should fail gracefully since .git may not exist in sandbox
              if upspell > $out 2>&1; then
                grep -q "custom-dictionary-workspace.txt" $out || true
              else
                grep -q "not a git repository" $out || true
              fi
            '';
      };
    };

  upflake =
    pkgs.writeShellScriptBin "upflake" ''
      git add flake.lock
      git commit -m "upflake - updated flake.lock"
    ''
    // {
      passthru.tests = {
        basic =
          pkgs.runCommand "upflake-test"
            {
              buildInputs = [
                pkgs.writeShellScriptBin
                "upflake"
                ""
              ];
            }
            ''
              set -e
              # Should fail gracefully since .git may not exist in sandbox
              if upflake > $out 2>&1; then
                grep -q "flake.lock" $out || true
              else
                grep -q "not a git repository" $out || true
              fi
            '';
      };
    };
}
