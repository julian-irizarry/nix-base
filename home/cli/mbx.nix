{ pkgs, nixBaseInputs, ... }:

let
  mbx = nixBaseInputs.mr-boxington.packages.${pkgs.stdenv.hostPlatform.system}.mbx;
in
{
  home.packages = [ mbx ];

  # Dev shells put their own cargo first on PATH, so re-add mbx's cargo shim
  # after `use flake` / `use nix`; the shim delegates to the shell's cargo.
  # direnv sources lib/*.sh in glob order, so this wraps nix-direnv's
  # functions from hm-nix-direnv.sh before any .envrc runs. Not on the global
  # PATH: outside dev shells there is no cargo for the shim to delegate to.
  xdg.configFile."direnv/lib/mbx.sh".text = ''
    for __mbx_use in use_flake use_nix; do
      if declare -f "$__mbx_use" >/dev/null; then
        eval "__mbx_orig_$(declare -f "$__mbx_use")"
        eval "$__mbx_use() { __mbx_orig_$__mbx_use \"\$@\" && PATH_add ${mbx}/libexec/mbx; }"
      fi
    done
    unset __mbx_use
  '';
}
