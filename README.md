# home-manager

Base home-manager module library. Cross-platform (Linux + macOS).

This repo is a **library** — it exposes a reusable module set and a small
`lib.mkHome` helper. It is not directly activatable. A thin "consumer" flake
supplies identity and calls `mkHome`.

## Structure

- `flake.nix` — exposes `homeModules.default`, `lib.mkHome`, and `checks`
- `lib/mkHome.nix` — helper wrapping `homeManagerConfiguration`
- `modules/` — reusable modules, grouped by concern
  - `options.nix` — `my.*` option surface (the public contract)
  - `home-defaults.nix` — derives `home.homeDirectory` from `home.username`
  - `default.nix` — imports every topical folder below
  - `cli/` — ripgrep, fd, jq, fzf, zoxide, direnv, gh, and friends
  - `editors/` — neovim (with absorbed lua config), vscode
  - `identity/` — git
  - `network/` — ssh
  - `nix/` — user-level nix.conf, allow-unfree predicate
  - `platform/` — linux and darwin specifics (gated by `pkgs.stdenv.hostPlatform.is*`)
  - `shell/` — zsh, oh-my-posh prompt
  - `terminal/` — kitty, tmux, fonts
- `docs/plans/` — design and implementation plans

## Supported systems

`x86_64-linux` and `aarch64-darwin` by default. `mkHome` accepts a `systems`
argument if you need to override (e.g. add `aarch64-linux`).

## Consumer flake

Minimal single-file flake that imports this one and sets identity. Live
somewhere private, e.g. `~/repos/home-manager-personal`.

```nix
{
  description = "Personal home-manager config";

  inputs.home-manager-base.url = "github:<user>/home-manager";

  outputs =
    { home-manager-base, ... }:
    {
      homeConfigurations = home-manager-base.lib.mkHome {
        modules = [
          {
            home.username = "your-unix-user";

            my.git.userName = "Your Name";
            my.git.userEmail = "you@example.com";
          }
        ];
      };
    };
}
```

`mkHome` returns an attrset keyed by system string, so you activate with
`--flake .#x86_64-linux` or `--flake .#aarch64-darwin`. `home.homeDirectory`
and `home.stateVersion` are derived for you; override via `lib.mkForce` in
the consumer module if you need something non-standard.

## Activate

From the consumer flake directory:

```bash
nix run home-manager/master -- switch --flake .#x86_64-linux
# or .#aarch64-darwin on macOS
```

One-liner alias for daily use:

```bash
alias hms='home-manager switch --flake .#x86_64-linux'
```

## First-time setup

```bash
# Clone both repos.
git clone git@github.com:<user>/home-manager.git          ~/repos/home-manager
git clone git@github.com:<user>/home-manager-personal.git ~/repos/home-manager-personal

cd ~/repos/home-manager-personal

# Fetch inputs and activate.
nix run home-manager/master -- switch --flake .#x86_64-linux
```

## Development — iterate on base with a local checkout

While hacking on this repo, point the consumer flake at your local checkout
instead of the published github URL. No commit needed in base — nix picks up
the working tree.

```bash
cd ~/repos/home-manager-personal

home-manager switch --flake .#x86_64-linux \
  --override-input home-manager-base path:../home-manager
```

Alias it:

```bash
alias hms-dev='home-manager switch --flake .#x86_64-linux --override-input home-manager-base path:../home-manager'
```

When you're happy with base changes, commit and push them in
`~/repos/home-manager`. The consumer flake's `flake.lock` stays pointing at
the github URL — no lock-file pollution from the override flag. Update base
pins explicitly with `nix flake update home-manager-base`.

## Verify base in isolation

The base flake's `checks.<system>.default` smoke-builds the module tree with
dummy identity values, so you can verify modules evaluate without a consumer:

```bash
cd ~/repos/home-manager
nix flake check
```
