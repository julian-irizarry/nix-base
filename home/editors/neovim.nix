{ ... }:

{
  programs.neovim = {
    enable = true;
    viAlias = true;
    vimAlias = true;
    defaultEditor = true;
    withPython3 = false;
    withRuby = false;
    withNodeJs = false;
  };

  xdg.configFile."nvim".source = ./neovim;
}
