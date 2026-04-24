{
  config,
  pkgs,
  lib,
  ...
}:

{
  programs.vscode = {
    enable = true;

    profiles.default = {
      extensions = with pkgs.vscode-extensions; [
        vscodevim.vim
        mkhl.direnv
        jnoortheen.nix-ide
        bbenoist.nix
        ms-vscode-remote.remote-containers
        ms-azuretools.vscode-docker
        llvm-vs-code-extensions.vscode-clangd
        rust-lang.rust-analyzer
        eamodio.gitlens
      ];

      userSettings = {
        "editor.fontFamily" = config.my.font.name;
        "editor.fontSize" = config.my.font.size;
        "editor.formatOnSave" = true;
        "editor.renderWhitespace" = "boundary";
        "editor.rulers" = [ 100 ];
        "editor.bracketPairColorization.enabled" = true;
        "editor.minimap.enabled" = false;

        "files.trimTrailingWhitespace" = true;
        "files.insertFinalNewline" = true;
        "files.trimFinalNewlines" = true;

        "terminal.integrated.fontFamily" = config.my.font.name;
        "terminal.integrated.fontSize" = config.my.font.size;
        "terminal.integrated.defaultProfile.linux" = "zsh";
        "terminal.integrated.defaultProfile.osx" = "zsh";

        "workbench.editor.enablePreview" = false;
        "workbench.startupEditor" = "none";

        "git.confirmSync" = false;
        "git.autofetch" = true;
        "git.enableSmartCommit" = true;

        "nix.enableLanguageServer" = true;
        "nix.serverPath" = "nixd";
        "nix.formatterPath" = "nixfmt";

        "direnv.restart.automatic" = true;
      };
    };
  };
}
