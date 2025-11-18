{ pkgs, ... }:

{
  programs.git = {
    enable = true;
    extraConfig = {
      user = {
        useConfigOnly = true;
        name = "Maxwell Rupp";
        email = "maxwell@giglab.dev";
      };
      pull.rebase = true;
      merge.ff = false;
      # pull.ff = "only";
      init.defaultBranch = "main";
      diff.tool = "diffview";
      difftool = {
        # Defines the specific command for the difftool named 'diffview'.
        # This command launches Neovim in diff mode on the local and remote files.
        # Diffview.nvim detects this state and takes over the display.
        diffview = {
          cmd = "nvim -d \"$LOCAL\" \"$REMOTE\"";
        };
      };

      # ✠ Merge Tool Configuration (Diffview) ✠
      merge = {
        # Sets the default mergetool to 'diffview'.
        tool = "diffview";
      };

      mergetool = {
        # Defines the specific command for the mergetool named 'diffview'.
        diffview = {
          diffview = {
            cmd = "nvim --cmd 'set ft=git' -c 'DiffviewOpen --base \"$BASE\" --local \"$LOCAL\" --remote \"$REMOTE\" --mergetool \"$MERGED\"'";
            keepBackup = false;
            prompt = false;
            trustExitCode = true;
          };
        };
      };
    };
    lfs.enable = true;
  };

  home.packages = with pkgs; [
    git-lfs
    gitflow
    gnupg
    pinentry
  ];
  # # Debug statement to ensure the file is being processed
  # environment.etc."gitconfig".text = ''
  #     [pull]
  #         rebase = true
  # '';
}
