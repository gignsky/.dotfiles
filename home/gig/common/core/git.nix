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
          cmd = "nvim -d \"$REMOTE\" \"$LOCAL\"";
        };
      };

      # ✠ Merge Tool Configuration (Diffview) ✠
      merge = {
        # Sets the default mergetool to 'diffview'.
        tool = "diffview";
      };

      mergetool = {
        # Defines the specific configuration for the 'diffview' mergetool.
        # The tool properties (cmd, keepBackup, etc.) must reside directly here.
        diffview = {
          # The corrected 'cmd' attribute
          # cmd = "nvim --cmd 'set ft=git' -c 'DiffviewOpen --base \"$BASE\" --local \"$LOCAL\" --remote \"$REMOTE\" --mergetool \"$MERGED\"'";
          cmd = "sh -c 'nvim --cmd \"set ft=git\" -c \"DiffviewOpen --base \\\"$1\\\" --local \\\"$2\\\" --remote \\\"$3\\\" --mergetool \\\"$4\\\"\"'";

          # Prevents Git from prompting to delete the temporary .orig file.
          keepBackup = false;

          # Prevents Git from prompting before launching the tool for each file.
          prompt = false;

          # ***This is the vital addition to fix the $BASE error.***
          trustExitCode = true;
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
