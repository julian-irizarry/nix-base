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
        github.github-vscode-theme
      ];

      # Merged into a writable settings.json on each switch (these values win),
      # so changes made from VS Code's UI persist instead of failing to save.
      mutableUserSettings = true;

      userSettings = {
        "editor.fontFamily" = config.my.font.name;
        "editor.fontSize" = config.my.font.size;
        "editor.formatOnSave" = true;
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
        "workbench.colorTheme" = "GitHub Dark Default";
        # Whole-block insertions stack the line and text tints, so keep both faint.
        "workbench.colorCustomizations" = {
          "diffEditor.insertedLineBackground" = "#2ea0431a";
          "diffEditor.insertedTextBackground" = "#2ea0430d";
          "diffEditor.removedLineBackground" = "#f851491a";
          "diffEditor.removedTextBackground" = "#f851490d";
          "diffEditorGutter.insertedLineBackground" = "#2ea04333";
          "diffEditorGutter.removedLineBackground" = "#f8514933";
          "diffEditor.diagonalFill" = "#00000000";
        };

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
