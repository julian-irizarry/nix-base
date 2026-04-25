{ config, lib, ... }:

let
  cfg = config.sys.swap;

  # True iff mountpoint `mp` is a directory ancestor of `path`. Path-boundary
  # aware: "/swap" must NOT match "/swapping/x", and "/" matches every
  # absolute path.
  isPathAncestor = mp: path: mp == "/" || mp == path || lib.hasPrefix (mp + "/") path;

  # Longest fileSystems mountpoint that contains cfg.path. Deeper mounts win
  # ("/swap" beats "/" for "/swap/swapfile"). null when no fileSystems entry
  # contains the swap path (consumer error — module emits a warning below).
  swapMount =
    let
      matches = lib.filter (fs: fs.mountPoint != null && isPathAncestor fs.mountPoint cfg.path) (
        lib.attrValues config.fileSystems
      );
    in
    lib.foldl' (
      acc: fs:
      if acc == null || lib.stringLength fs.mountPoint > lib.stringLength acc.mountPoint then fs else acc
    ) null matches;
in
lib.mkIf (cfg.size != null) {
  swapDevices = [
    {
      device = cfg.path;
      size = cfg.size;
    }
  ];

  # Only set resumeDevice when we found a real device — option type is str.
  boot.resumeDevice = lib.mkIf (cfg.enableHibernate && swapMount != null) swapMount.device;

  boot.kernelParams = lib.mkIf (cfg.enableHibernate && cfg.resumeOffset != null) [
    "resume_offset=${toString cfg.resumeOffset}"
  ];

  warnings =
    lib.optional (cfg.enableHibernate && cfg.resumeOffset == null)
      "sys.swap.enableHibernate is true but sys.swap.resumeOffset is null — hibernate won't resume. Compute via `btrfs inspect-internal map-swapfile -r ${cfg.path}` (btrfs) or `filefrag -e ${cfg.path} | head -2` (ext4) and set the option."
    ++
      lib.optional (cfg.enableHibernate && swapMount == null)
        "sys.swap.enableHibernate is true but no fileSystems entry contains sys.swap.path (${cfg.path}). boot.resumeDevice will be unset; hibernate will not resume.";
}
