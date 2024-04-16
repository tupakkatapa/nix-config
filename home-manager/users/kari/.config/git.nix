{ pkgs, ... }: {
  programs.git = {
    enable = true;
    package = pkgs.gitFull;
    signing.key = "773DC99EDAF29D356155DC91269CF32D790D1789";
    signing.signByDefault = true;
    userEmail = "jesse@ponkila.com";
    userName = "tupakkatapa";
    extraConfig = {
      safe.directory = [ "*" ];
      http = {
        # https://stackoverflow.com/questions/22369200/git-pull-push-error-rpc-failed-result-22-http-code-408
        postBuffer = "524288000";
      };
    };
  };
}
