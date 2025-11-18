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
          # This is a critical command. It opens Neovim and executes the
          # DiffviewOpen command with all four necessary merge buffers ($BASE,
          # $LOCAL, $REMOTE, $MERGED) and the required '--mergetool' flag
          # for conflict resolution.
          cmd = "nvim --cmd 'set ft=git' -c 'DiffviewOpen --base \"$BASE\" --local \"$LOCAL\" --remote \"$REMOTE\" --mergetool \"$MERGED\"'";

          # Prevents Git from prompting to delete the temporary .orig file.
          keepBackup = false;

          # Prevents Git from prompting before launching the tool for each file
          # during a merge conflict resolution session.
          prompt = false;
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
