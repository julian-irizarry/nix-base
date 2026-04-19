# home-manager (base)

Cross-platform home-manager **library** flake. Not directly activatable — it exposes
`homeModules.default` and `lib.mkHome` for a private "extended" consumer flake to
import. Keep this repo public-safe: no identity, no secrets, no internal hostnames.

See `docs/plans/2026-04-18-home-manager-migration-design.md` for the full design
rationale (two-flake split, secret handling, platform strategy).

## Commands

```bash
# Format (treefmt-nix: nixfmt + stylua + prettier)
nix fmt

# Evaluate modules + formatting check (the "test suite")
nix flake check --show-trace

# Smoke-build the activation package without activating (dummy identity)
nix build .#checks.x86_64-linux.default         # Linux
nix build .#checks.aarch64-darwin.default       # macOS

# Iterate from a consumer flake against this local checkout (no commit needed)
home-manager switch --flake .#<system> \
  --override-input home-manager-base path:/home/jirizarry/Downloads/repos/home-manager
```

Supported systems: `x86_64-linux`, `aarch64-darwin`. `mkHome` accepts a `systems`
arg to add more.

## Architecture

- `flake.nix` — exposes `homeModules.default`, `lib.mkHome`, `formatter`, `checks`.
  `checks.default` is a smoke build of the module tree with placeholder identity,
  so `nix flake check` catches regressions without a real consumer.
- `lib/mkHome.nix` — thin wrapper over `home-manager.lib.homeManagerConfiguration`;
  returns an attrset keyed by system string.
- `modules/options.nix` — the **public contract**. Everything Claude touches that
  varies between personal/work lives here under `my.*`. Keep this surface small.
- `modules/default.nix` — imports every topical folder. Platform gating happens
  inside each platform module via `lib.mkIf pkgs.stdenv.hostPlatform.is{Linux,Darwin}`
  (not at the import level).
- `modules/home-defaults.nix` — derives `home.homeDirectory` from `home.username`
  and sets `home.stateVersion`. Uses `lib.mkDefault` so consumers can override.
- `modules/{cli,editors,identity,network,nix,platform,shell,terminal}/` — topical
  module folders. Each has a `default.nix` that imports its siblings.

## The `my.*` option surface

Only values that genuinely differ between consumers are options. Everything else
(aliases, plugins, tool list, kitty/tmux/nvim configs) stays hardcoded.

- `my.git.{userName,userEmail,signingKey,signingFormat,extraIncludes}` — identity
  and signing. `signingFormat` defaults to `"ssh"` (matches Anduril's flow).
- `my.nix.{extraNixPath,extraExperimentalFeatures,extraSubstituters,extraTrustedPublicKeys,extraSettings}`
  — appended to the base nix.conf. `extra-substituters` requires daemon trust
  (configured outside nix on Determinate installs).
- `my.zsh.extraInitFragments` — list of shell snippets concatenated at the **end**
  of the generated `.zshrc`. Primary secret-wiring mechanism (e.g. `op read` at
  shell init). Graceful fallback when `op` is missing is the fragment author's job.
- `my.ssh.extraHosts` — attrset of matchBlock specs, rendered to
  `~/.ssh/config.d/hm-hosts` (not `~/.ssh/config` — see SSH gotcha below).
- `my.font.{nerdFamily,name,size}` — `nerdFamily` indexes `pkgs.nerd-fonts.*`;
  `name` is the rendered family name terminals/editors reference. They must match.

## Non-obvious patterns / gotchas

- **SSH config is not owned by home-manager.** `latticectl` writes to
  `~/.ssh/config`, so `modules/network/ssh.nix` renders `my.ssh.extraHosts` to
  `~/.ssh/config.d/hm-hosts` and expects the user to `Include config.d/hm-hosts`
  once at the top of `~/.ssh/config`. Do **not** switch this to `programs.ssh` —
  latticectl will clobber it.
- **1Password SSH agent wiring is deferred.** `modules/platform/darwin.nix` is a
  placeholder for the `IdentityAgent` socket path. Linux path is
  `~/.1password/agent.sock`, macOS is under
  `~/Library/Group Containers/.../agent.sock`. Configure per-platform, not shared.
- **Login shell is not managed by home-manager.** Run `chsh -s $(which zsh)` once
  per fresh machine. An earlier activation hook did this automatically via
  `sudo chsh` but was removed — it prompted for a password on every switch and
  broke non-interactive activations.
- **`initContent` ordering matters.** `modules/shell/zsh.nix` uses `lib.mkMerge`
  with `mkBefore` (sources `.zshenv.local`), the default slot (bindkeys, completion
  zstyles, widgets, sources `.zshrc.local`), and `mkAfter` (concatenates
  `my.zsh.extraInitFragments`). Extended-flake secrets must land last.
- **Tools use real binaries, not Debian aliases.** `fd`/`bat`/`eza` come from
  nixpkgs — don't reintroduce `fdfind`/`batcat` shims.
- **`modules/shell/omp.json`** is excluded from prettier in `treefmt.nix`
  (oh-my-posh's schema uses nonstandard formatting). Don't re-enable it.
- **Secrets never live in this repo.** Any secret wiring belongs in the extended
  flake's `work-secrets.nix` via `my.zsh.extraInitFragments`. Reject PRs that add
  plaintext tokens, identity emails, or internal hostnames here.

## Consumer flake shape

```nix
home-manager-base.lib.mkHome {
  modules = [{
    home.username = "you";
    my.git.userName  = "Your Name";
    my.git.userEmail = "you@example.com";
  }];
};
```

Activate with `--flake .#x86_64-linux` or `.#aarch64-darwin`. `home.homeDirectory`
and `home.stateVersion` are derived; override via `lib.mkForce` if needed.

## Workflow expectations

- One commit per logical change; keep commit subjects in the style of
  `feat(<area>): ...`, `refactor(<area>): ...`, `chore: ...` (see `git log`).
- Run `nix fmt && nix flake check --show-trace` before claiming work is done —
  evaluation errors and formatting drift are the two most common breakages.
- **Never run `git commit` without explicit user approval** (see global
  `~/.claude/CLAUDE.md`).
- Prefer adding a new `my.*` option only when a value genuinely differs between
  personal and work use. Hardcode otherwise.
- **Comment sparingly.** Only comment when the code is not obvious — hidden
  constraints, workarounds, ordering requirements, or surprising choices.
  Don't restate what the code plainly does.
