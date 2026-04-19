{ config, ... }:

{
  programs.git = {
    enable = true;
    signing = {
      key = config.my.git.signingKey;
      signByDefault = config.my.git.signingKey != null;
      format = config.my.git.signingFormat;
    };
    includes = config.my.git.extraIncludes;
    settings = {
      user.name = config.my.git.userName;
      user.email = config.my.git.userEmail;
      init.defaultBranch = "main";
      pull.ff = "only";
      merge.tool = "vimdiff";
      core.editor = "nvim";
    };
  };
}
