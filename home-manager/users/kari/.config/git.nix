{ pkgs, ... }:
{
  programs.git = {
    enable = true;
    package = pkgs.gitFull;
    lfs.enable = true;

    ignores = [
      ".knowledge"
      ".scripts"
      "TODO.md"
      "PROMPTS.md"
      "MEMO.md"
    ];

    settings = {
      alias.uncommit = "reset --soft HEAD^";
      branch.sort = "-committerdate";
      column.ui = "auto";
      commit.verbose = true;
      diff = {
        algorithm = "histogram";
        colorMoved = "plain";
        mnemonicPrefix = true;
        renames = true;
      };
      fetch = {
        all = true;
        prune = true;
        pruneTags = true;
      };
      http.postBuffer = "524288000";
      init.defaultBranch = "main";
      merge.conflictstyle = "zdiff3";
      pull.rebase = true;
      push = {
        autosetupremote = true;
        default = "simple";
        followTags = true;
      };
      rebase = {
        autoSquash = true;
        autoStash = true;
        updateRefs = true;
      };
      safe.directory = [ "*" ];
      tag.sort = "version:refname";
    };
  };
}
