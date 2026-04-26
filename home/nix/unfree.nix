# Unfree allowlist is set at the nixpkgs level in lib/mkSystem.nix and
# lib/mkHome.nix (allowUnfree = true). Nothing to declare here for NixOS-
# integrated home-manager; mkHome sets its own allowUnfree on the pkgs it
# constructs.
{ }
