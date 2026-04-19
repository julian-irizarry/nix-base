{
  config,
  lib,
  pkgs,
  ...
}:

lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
  programs.ssh.matchBlocks."*".extraOptions = {
    IdentityAgent = "~/.1password/agent.sock";
  };

  home.activation.make-zsh-default-shell = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    PATH="/usr/bin:/bin:$PATH"
    ZSH_PATH="${config.home.profileDirectory}/bin/zsh"
    if [[ $(getent passwd "${config.home.username}") != *"$ZSH_PATH" ]]; then
      echo "Setting zsh as default shell via chsh. Password may be required."
      if ! grep -q "$ZSH_PATH" /etc/shells; then
        echo "Adding $ZSH_PATH to /etc/shells."
        sudo sh -c "echo '$ZSH_PATH' >> /etc/shells"
      fi
      sudo chsh -s "$ZSH_PATH" "${config.home.username}"
    fi
  '';
}
