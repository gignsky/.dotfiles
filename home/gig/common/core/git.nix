{ pkgs, ... }:

{
    programs.git = {
        enable = true;
        extraConfig = {
            user.useConfigOnly = true;
            user.name = "gignsky";
            user.email = "gig@gignsky.com";
            pull.rebase = true;
            merge.ff = false;
            # pull.ff = "only";
            init.defaultBranch = "main";
        };
    };

    home.packages = with pkgs; [
        git-lfs
    ];
    # # Debug statement to ensure the file is being processed
    # environment.etc."gitconfig".text = ''
    #     [pull]
    #         rebase = true
    # '';
}