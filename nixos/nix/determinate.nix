{ inputs, config, ... }:
{
  imports = [ inputs.determinate.nixosModules.default ];

  # Upstream defaults determinate.enable = true; mirror our toggle so the daemon
  # only activates when sys.determinate.enable is explicitly set.
  determinate.enable = config.sys.determinate.enable;
}
