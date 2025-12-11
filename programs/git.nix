{ pkgs, ... }:

{
  programs.git = {
    enable = true;
    settings = {
      user.name = "Julian Irizarry";
      user.email = "julianirizarry@live.com";
      init.defaultBranch = "main";
      pull.ff = "only";
      merge.tool = "vimdiff";
      credential.helper = "manager";
      credential.credentialStore = "secretservice";
      core.editor = "vim";
      core.autocrlf = "input";
    };
  };
}
