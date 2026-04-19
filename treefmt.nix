{ ... }:

{
  projectRootFile = "flake.nix";

  programs.nixfmt.enable = true;
  programs.stylua.enable = true;
  programs.prettier.enable = true;

  settings.global.excludes = [
    "flake.lock"
    "*.png"
    "*.jpg"
    "*.ico"
    "LICENSE"
    "**/.undodir/**"
  ];

  # omp.json uses nonstandard formatting; leave it alone.
  settings.formatter.prettier.excludes = [ "modules/shell/omp.json" ];
}
