# Home-Manager Migration Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Rebuild `julian-irizarry/home-manager` as a parameterized, cross-platform home-manager flake that provides the base layer for a private extended (work) flake to consume.

**Architecture:** Single base flake with native home-manager modules for every program (zsh, git, ssh, tmux, kitty, oh-my-posh, nvim, CLI tools). A small option surface under `my.*` lets the extended flake override identity, nix paths, SSH hosts, and shell init fragments without `lib.mkForce`. Platform differences are handled via `pkgs.stdenv.is{Linux,Darwin}` conditionally in `modules/default.nix`, with platform-specific modules under `modules/platform/`.

**Tech Stack:** Nix flakes, home-manager (nix-community), nixpkgs-unstable, nixfmt-rfc-style, pre-commit.

**Repo location:** `~/Downloads/repos/home-manager` (keep existing path; user has personal `user.name`/`user.email` already configured per-repo; remote is HTTPS for GCM auth).

**Design doc:** `docs/plans/2026-04-18-home-manager-migration-design.md`

---

## Verification model (read this first)

Nix does not have unit tests in the classical sense. Instead, each task ends with these verifications:

1. **`nixfmt` or `nix fmt`** — format the file.
2. **`nix flake check --show-trace`** — evaluates every output, type-checks options, and is our "test suite" for config correctness.
3. **`home-manager build --flake .#linux`** (on this Linux machine) — builds the home-manager activation package without activating. Fails if anything about the module actually breaks the build.
4. **`git commit`** — one commit per task, message format described per task.

`home-manager switch` (the activation step) is deferred until the cutover task (Task 16). Before that, we only **build**, never activate, to avoid disturbing the working shell.

If `nix flake check` or `home-manager build` fails, fix before moving on. If you're stuck, pause and report the error; do not proceed with a broken module.

**Pre-flight — run once before starting:**

```bash
cd ~/Downloads/repos/home-manager
git status
git remote -v
git config user.name
git config user.email
```

Expected: working tree clean, remote is `https://github.com/julian-irizarry/home-manager.git`, `user.name = julian-irizarry`, `user.email = <id>+julian-irizarry@users.noreply.github.com`.

If the working tree is not clean, stop and ask.

---

## Phase 1 — Scaffolding (Tasks 1-4)

### Task 1: Wipe the old flake content, keep `.gitignore`, `.pre-commit-config.yaml`, and `docs/`

**Goal:** Start from an empty tree. The old flake had useful reference patterns we've already extracted into the design doc. Keep config files and docs.

**Files:**

- Delete: `flake.nix`, `flake.lock`, `home.nix`, `programs/` (directory), `packages/` (directory)
- Keep: `.gitignore`, `.pre-commit-config.yaml`, `docs/`, `.git/`

**Step 1: Inspect what's there**

```bash
cd ~/Downloads/repos/home-manager
ls -la
```

Expected: see `flake.nix`, `flake.lock`, `home.nix`, `packages/`, `programs/`, `.gitignore`, `.pre-commit-config.yaml`, `docs/`, `.git/`.

**Step 2: Delete the old flake code**

```bash
rm flake.nix flake.lock home.nix
rm -rf programs packages
```

**Step 3: Verify**

```bash
ls -la
```

Expected: only `.git/`, `.gitignore`, `.pre-commit-config.yaml`, `docs/` remain.

**Step 4: Commit**

```bash
git add -A
git commit -m "chore: remove legacy flake to prepare for rewrite

The previous flake has been superseded by the design in
docs/plans/2026-04-18-home-manager-migration-design.md. Legacy
modules are removed in one commit so the new structure lands clean."
```

---

### Task 2: Update `.gitignore` and add `README.md`

**Goal:** Minimal README so GitHub landing page makes sense. Extend .gitignore with HM state paths.

**Files:**

- Modify: `.gitignore`
- Create: `README.md`

**Step 1: Append HM state paths to `.gitignore`**

Open `.gitignore` and append:

```
# home-manager local state (never checked in)
result
result-*
```

(If those lines already exist, skip.)

**Step 2: Write `README.md`**

````markdown
# home-manager

Base home-manager flake. Cross-platform (Linux + macOS).

## Activate

```bash
nix run home-manager/master -- switch --flake .#linux   # or .#mac
```
````

## Structure

- `flake.nix` — inputs, outputs, `homeConfigurations.{linux,mac}`
- `lib/mkHome.nix` — builder helper parameterized by system
- `modules/` — all reusable modules
  - `options.nix` — `my.*` option surface
  - `default.nix` — imports everything + platform conditional
  - `shell/`, `dev/`, `platform/` — grouped modules
- `docs/plans/` — design and implementation plans

Work-specific overlays live in a separate private flake that imports this one.

````

**Step 3: Verify + commit**

```bash
git add -A
git commit -m "chore: add README and extend gitignore for home-manager state"
````

---

### Task 3: Write `flake.nix` + `lib/mkHome.nix` with empty module

**Goal:** Minimum evaluable flake. `nix flake check` passes. `home-manager build --flake .#linux` succeeds (produces an empty-but-valid HM generation).

**Files:**

- Create: `flake.nix`
- Create: `lib/mkHome.nix`
- Create: `modules/default.nix` (placeholder — imports nothing yet)

**Step 1: Create `modules/default.nix` (placeholder)**

```bash
mkdir -p modules lib
```

`modules/default.nix`:

```nix
{ pkgs, lib, ... }:

{
  # Module imports will be added task-by-task.
  imports = [ ];
}
```

**Step 2: Create `lib/mkHome.nix`**

```nix
{ nixpkgs, home-manager }:

system:

home-manager.lib.homeManagerConfiguration {
  pkgs = nixpkgs.legacyPackages.${system};
  modules = [
    ../modules
    {
      home.stateVersion = "25.05";
      home.username = "jirizarry";
      home.homeDirectory =
        if nixpkgs.lib.hasInfix "darwin" system
        then "/Users/jirizarry"
        else "/home/jirizarry";

      # Base-flake defaults for `my.*` — these are the personal values.
      # The extended flake overrides these via its own module values.
    }
  ];
}
```

NOTE: `my.*` defaults will be supplied by `modules/options.nix` once it exists. For now, the builder just provides `home.*`. We'll wire `my.*` defaults in Task 4.

**Step 3: Create `flake.nix`**

```nix
{
  description = "Base home-manager configuration (cross-platform)";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { nixpkgs, home-manager, ... }:
    let
      mkHome = import ./lib/mkHome.nix { inherit nixpkgs home-manager; };
    in
    {
      # Exposed for the extended flake to consume.
      homeModules.default = ./modules;

      homeConfigurations = {
        linux = mkHome "x86_64-linux";
        mac   = mkHome "aarch64-darwin";
      };
    };
}
```

**Step 4: Format**

```bash
nix fmt . 2>/dev/null || nix run nixpkgs#nixfmt-rfc-style -- flake.nix lib/mkHome.nix modules/default.nix
```

If neither `nix fmt` nor the fallback works, install nixfmt once: `nix profile install nixpkgs#nixfmt-rfc-style`, then rerun the fallback.

**Step 5: Evaluate**

```bash
nix flake check --show-trace
```

Expected: completes without error. You may see warnings about missing `flake.lock`; that's fine — it will be created.

If you see "path does not exist" for `./modules`, ensure `modules/default.nix` exists and is syntactically valid.

**Step 6: Build**

```bash
nix build .#homeConfigurations.linux.activationPackage --show-trace
```

Expected: builds a `./result` symlink. (The result is harmless — it's just the HM activation script that we are NOT running.)

```bash
rm -f result
```

**Step 7: Commit**

```bash
git add -A
git commit -m "feat: scaffold base flake with empty module tree

Adds flake.nix with homeConfigurations.{linux,mac}, a system-parameterized
mkHome helper in lib/, and a placeholder modules/default.nix. No functional
modules yet. 'nix flake check' and 'home-manager build --flake .#linux'
both succeed."
```

---

### Task 4: Add `modules/options.nix` with the `my.*` surface + wire it in

**Goal:** Lock in the parameterization contract. Expose `my.git.*`, `my.nix.extraNixPath`, `my.zsh.extraInitFragments`, `my.ssh.extraHosts`.

**Files:**

- Create: `modules/options.nix`
- Modify: `modules/default.nix` (import options)
- Modify: `lib/mkHome.nix` (supply personal defaults for `my.*`)

**Step 1: Create `modules/options.nix`**

```nix
{ lib, ... }:

{
  options.my = {
    git = {
      userName = lib.mkOption {
        type = lib.types.str;
        description = "Git user.name.";
      };
      userEmail = lib.mkOption {
        type = lib.types.str;
        description = "Git user.email.";
      };
      signingKey = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Git signing key (SSH private key path for ssh format, or GPG key id). Null disables signing.";
      };
      signingFormat = lib.mkOption {
        type = lib.types.enum [ "openpgp" "ssh" "x509" ];
        default = "ssh";
        description = "Git commit signing format. Default ssh matches Anduril's signing flow.";
      };
      extraIncludes = lib.mkOption {
        type = lib.types.listOf lib.types.attrs;
        default = [ ];
        description = ''
          List of conditional includes for ~/.gitconfig. Each entry is
          { condition = "gitdir:..."; contents = { ... }; }.
        '';
      };
    };

    nix.extraNixPath = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Additional entries appended to NIX_PATH.";
    };

    zsh.extraInitFragments = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = ''
        Shell fragments appended to the generated .zshrc. Used by the extended
        flake for secret wiring (op-based env vars) and work-only aliases.
      '';
    };

    ssh.extraHosts = lib.mkOption {
      type = lib.types.attrsOf lib.types.attrs;
      default = { };
      description = ''
        Additional ssh matchBlocks keyed by host name. Merged into
        programs.ssh.matchBlocks.
      '';
    };
  };
}
```

**Step 2: Import `options.nix` from `modules/default.nix`**

Update `modules/default.nix`:

```nix
{ pkgs, lib, ... }:

{
  imports = [
    ./options.nix
  ];
}
```

**Step 3: Supply personal defaults in `lib/mkHome.nix`**

Replace the inline module content with:

```nix
{ nixpkgs, home-manager }:

system:

home-manager.lib.homeManagerConfiguration {
  pkgs = nixpkgs.legacyPackages.${system};
  modules = [
    ../modules
    {
      home.stateVersion = "25.05";
      home.username = "jirizarry";
      home.homeDirectory =
        if nixpkgs.lib.hasInfix "darwin" system
        then "/Users/jirizarry"
        else "/home/jirizarry";

      my.git.userName = "julian-irizarry";
      my.git.userEmail = "julianirizarry@live.com";
      # my.git.signingKey left null by default
      # my.git.extraIncludes left [] by default
      # my.nix.extraNixPath left [] by default
      # my.zsh.extraInitFragments left [] by default
      # my.ssh.extraHosts left {} by default
    }
  ];
}
```

(If the personal email should be the GitHub noreply form instead, change `userEmail` accordingly.)

**Step 4: Format, check, build**

```bash
nix run nixpkgs#nixfmt-rfc-style -- modules/options.nix modules/default.nix lib/mkHome.nix
nix flake check --show-trace
nix build .#homeConfigurations.linux.activationPackage --show-trace
rm -f result
```

Expected: all three succeed. If `nix flake check` errors with "option does not exist" for `my.git.userName`, the import path from `default.nix` is wrong — fix before continuing.

**Step 5: Commit**

```bash
git add -A
git commit -m "feat: add my.* option surface and wire personal defaults"
```

---

## Phase 2 — Core modules (Tasks 5-14)

Each task in this phase follows the same pattern:

1. Create the module file.
2. Add its import to `modules/default.nix`.
3. Format with nixfmt.
4. `nix flake check` must pass.
5. `home-manager build --flake .#linux` must succeed.
6. Commit.

If you deviate from the pattern, say so explicitly.

---

### Task 5: `modules/git.nix`

**Files:**

- Create: `modules/git.nix`
- Modify: `modules/default.nix`

**Step 1: Create `modules/git.nix`**

```nix
{ config, ... }:

{
  programs.git = {
    enable = true;
    userName = config.my.git.userName;
    userEmail = config.my.git.userEmail;
    signing = {
      key = config.my.git.signingKey;
      signByDefault = config.my.git.signingKey != null;
      format = config.my.git.signingFormat;
    };
    includes = config.my.git.extraIncludes;
    extraConfig = {
      init.defaultBranch = "main";
      pull.ff = "only";
      merge.tool = "vimdiff";
      core.editor = "nvim";
    };
  };
}
```

NOTE: Dropped GCM (`credential.helper = "manager"`, `credentialStore`, `useHttpPath`) and `core.autocrlf` — those were Windows/HTTPS-auth artifacts from the old flake. On Linux/macOS with SSH remotes they're inert at best and confusing at worst. `programs.gpg.enable` also dropped from base; Anduril uses SSH signing, not GPG, and nothing in the base needs a GPG agent.

Anduril-specific settings (`url.insteadOf` rewrite, `user.email = $USER@anduril.com`, signing key path) live in the **extended** flake — it overrides `my.git.userEmail`, sets `my.git.signingKey = "~/.ssh/id_ed25519"`, and adds `programs.git.extraConfig.url."git@ghe.anduril.dev:".insteadOf = "https://ghe.anduril.dev"`.

**Step 2: Wire in `modules/default.nix`**

```nix
{ pkgs, lib, ... }:

{
  imports = [
    ./options.nix
    ./git.nix
  ];
}
```

**Step 3: Format, check, build**

```bash
nix run nixpkgs#nixfmt-rfc-style -- modules/git.nix modules/default.nix
nix flake check --show-trace
nix build .#homeConfigurations.linux.activationPackage --show-trace
rm -f result
```

**Step 4: Commit**

```bash
git add -A
git commit -m "feat: add git module reading from my.git.* options"
```

---

### Task 6: `modules/dev/cli-tools.nix`

**Goal:** Native modules for fzf, zoxide, bat, eza, direnv, gh, less, man, readline, uv. Plus `home.packages` for tools without a home-manager module (ripgrep, fd, jq, yq, tree, wget, curl, unzip, zip, xclip, btop, gnupg, gnumake, pkg-config, tmux — wait, tmux gets its own module; drop from here).

**Files:**

- Create: `modules/dev/cli-tools.nix`
- Modify: `modules/default.nix`

**Step 1: Create `modules/dev/cli-tools.nix`**

```bash
mkdir -p modules/dev
```

```nix
{ pkgs, ... }:

{
  programs.bat.enable = true;
  programs.eza.enable = true;
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };
  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };
  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
  };
  programs.gh.enable = true;
  programs.less.enable = true;
  programs.man.enable = true;
  programs.readline.enable = true;
  programs.uv.enable = true;

  home.packages = with pkgs; [
    ripgrep
    fd
    jq
    yq-go
    tree
    wget
    curl
    unzip
    zip
    xclip
    btop
    gnumake
    pkg-config
  ];
}
```

NOTE: `yq` in nixpkgs is a Python wrapper; `yq-go` is the faster Go implementation commonly aliased as `yq`. Keep as `yq-go` unless user preference is otherwise.

**Step 2: Wire in `modules/default.nix`**

```nix
imports = [
  ./options.nix
  ./git.nix
  ./dev/cli-tools.nix
];
```

**Step 3: Format, check, build, commit**

```bash
nix run nixpkgs#nixfmt-rfc-style -- modules/dev/cli-tools.nix modules/default.nix
nix flake check --show-trace
nix build .#homeConfigurations.linux.activationPackage --show-trace
rm -f result
git add -A
git commit -m "feat: add cli-tools module with native home-manager programs"
```

---

### Task 7: `modules/shell/zsh.nix`

**Goal:** Port the old zsh module; replace `initExtra` with `initContent`; use `my.zsh.extraInitFragments` for the escape hatch.

**Files:**

- Create: `modules/shell/zsh.nix`
- Modify: `modules/default.nix`

**Step 1: Create `modules/shell/zsh.nix`**

```bash
mkdir -p modules/shell
```

```nix
{ config, lib, pkgs, ... }:

{
  home.sessionPath = [
    "$HOME/.local/bin"
    "$HOME/.npm-global/bin"
  ];

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    oh-my-zsh = {
      enable = true;
      theme = "robbyrussell";
      plugins = [ "git" ];
    };

    history = {
      size = 100000;
      save = 100000;
      ignoreAllDups = true;
      share = true;
    };

    shellAliases = {
      vim = "nvim";
      nd = "nix develop -vvv -c $SHELL";
      cd = "z";
      ls = "eza -a --icons=always";
      ll = "eza -lhag --icons=always";
      cat = "bat";
    };

    sessionVariables = {
      EDITOR = "nvim";
      ZSH = "$HOME/.oh-my-zsh";
    };

    initContent = lib.mkMerge [
      (lib.mkBefore ''
        # Sourced before oh-my-zsh initialization.
        [ -f "$HOME/.zshenv.local" ] && source "$HOME/.zshenv.local"
      '')
      ''
        # Custom keybindings.
        bindkey "^[[A" .up-line-or-history
        bindkey "^[[B" .down-line-or-history

        autoload -Uz edit-command-line
        zle -N edit-command-line

        # find + cd widget (Ctrl-F).
        find_and_cd_widget() {
          local dir
          dir=$(fd --type d --hidden --follow --exclude .git . ~/ \
            | fzf --preview 'tree -C {} | head -100' \
                  --preview-window=right:50%:wrap \
                  --height=40% --layout=reverse)

          if [[ -n "$dir" ]]; then
            BUFFER="cd $dir"
            zle accept-line
          else
            zle reset-prompt
          fi
        }
        zle -N find_and_cd_widget
        bindkey '^F' find_and_cd_widget

        # Recall last command onto the prompt.
        ag() { print -z "$(fc -ln -2 -2)"; }

        # Stage a rebuild command.
        hms() { print -z "home-manager switch --flake .#linux"; }

        # Escape hatch: source ~/.zshrc.local if it exists (non-managed overrides).
        [ -f "$HOME/.zshrc.local" ] && source "$HOME/.zshrc.local"
      ''
      (lib.mkAfter (lib.concatStringsSep "\n" config.my.zsh.extraInitFragments))
    ];
  };
}
```

NOTE: `initContent` replaces the deprecated `initExtra`. `lib.mkMerge` with ordered fragments (`mkBefore`, default order, `mkAfter`) produces a predictable `.zshrc` ordering.

**Step 2: Wire in `modules/default.nix`**

```nix
imports = [
  ./options.nix
  ./git.nix
  ./dev/cli-tools.nix
  ./shell/zsh.nix
];
```

**Step 3: Format, check, build, commit**

```bash
nix run nixpkgs#nixfmt-rfc-style -- modules/shell/zsh.nix modules/default.nix
nix flake check --show-trace
nix build .#homeConfigurations.linux.activationPackage --show-trace
rm -f result
git add -A
git commit -m "feat: add zsh module with my.zsh.extraInitFragments hook"
```

---

### Task 8: `modules/shell/prompt.nix` — oh-my-posh with absorbed `omp.json`

**Goal:** Bring the prompt config inside the flake. No dependency on the external dotfiles repo.

**Files:**

- Copy: `~/Downloads/repos/dotfiles/.config/oh-my-posh/omp.json` → `modules/shell/omp.json`
- Create: `modules/shell/prompt.nix`
- Modify: `modules/default.nix`

**Step 1: Copy the prompt JSON into the repo**

```bash
cp ~/Downloads/repos/dotfiles/.config/oh-my-posh/omp.json modules/shell/omp.json
```

**Step 2: Create `modules/shell/prompt.nix`**

```nix
{ ... }:

{
  programs.oh-my-posh = {
    enable = true;
    enableZshIntegration = true;
    settings = builtins.fromJSON (builtins.readFile ./omp.json);
  };
}
```

NOTE: `fromJSON` + `readFile` means the JSON is evaluated at build time. If the JSON is invalid, `nix flake check` will fail with a parse error, which is the desired feedback.

**Step 3: Wire in `modules/default.nix`**

```nix
imports = [
  ./options.nix
  ./git.nix
  ./dev/cli-tools.nix
  ./shell/zsh.nix
  ./shell/prompt.nix
];
```

**Step 4: Format, check, build, commit**

```bash
nix run nixpkgs#nixfmt-rfc-style -- modules/shell/prompt.nix modules/default.nix
nix flake check --show-trace
nix build .#homeConfigurations.linux.activationPackage --show-trace
rm -f result
git add -A
git commit -m "feat: add oh-my-posh module with absorbed omp.json"
```

---

### Task 9: `modules/ssh.nix`

**Goal:** `programs.ssh.matchBlocks` from `my.ssh.extraHosts`. 1Password IdentityAgent is configured in the per-platform modules (Task 14).

**Files:**

- Create: `modules/ssh.nix`
- Modify: `modules/default.nix`

**Step 1: Create `modules/ssh.nix`**

```nix
{ config, ... }:

{
  programs.ssh = {
    enable = true;
    matchBlocks = config.my.ssh.extraHosts;
  };
}
```

**Step 2: Wire in `modules/default.nix`**

```nix
imports = [
  ./options.nix
  ./git.nix
  ./ssh.nix
  ./dev/cli-tools.nix
  ./shell/zsh.nix
  ./shell/prompt.nix
];
```

**Step 3: Format, check, build, commit**

```bash
nix run nixpkgs#nixfmt-rfc-style -- modules/ssh.nix modules/default.nix
nix flake check --show-trace
nix build .#homeConfigurations.linux.activationPackage --show-trace
rm -f result
git add -A
git commit -m "feat: add ssh module reading from my.ssh.extraHosts"
```

---

### Task 10: `modules/nix-settings.nix`

**Goal:** `NIX_PATH` from `my.nix.extraNixPath`.

**Files:**

- Create: `modules/nix-settings.nix`
- Modify: `modules/default.nix`

**Step 1: Create `modules/nix-settings.nix`**

```nix
{ config, lib, ... }:

{
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  home.sessionVariables = lib.mkIf (config.my.nix.extraNixPath != [ ]) {
    NIX_PATH = lib.concatStringsSep ":" config.my.nix.extraNixPath;
  };
}
```

**Step 2: Wire + format + build + commit**

```nix
imports = [
  ./options.nix
  ./git.nix
  ./ssh.nix
  ./nix-settings.nix
  ./dev/cli-tools.nix
  ./shell/zsh.nix
  ./shell/prompt.nix
];
```

```bash
nix run nixpkgs#nixfmt-rfc-style -- modules/nix-settings.nix modules/default.nix
nix flake check --show-trace
nix build .#homeConfigurations.linux.activationPackage --show-trace
rm -f result
git add -A
git commit -m "feat: add nix-settings module with configurable NIX_PATH"
```

---

### Task 11: `modules/dev/tmux.nix`

**Goal:** Minimal tmux config via native module. The existing `~/.config/tmux/tmux.conf.bak` suggests tmux isn't actively configured; provide sensible defaults.

**Files:**

- Create: `modules/dev/tmux.nix`
- Modify: `modules/default.nix`

**Step 1: Create `modules/dev/tmux.nix`**

```nix
{ pkgs, ... }:

{
  programs.tmux = {
    enable = true;
    terminal = "tmux-256color";
    keyMode = "vi";
    mouse = true;
    baseIndex = 1;
    escapeTime = 10;
    historyLimit = 50000;

    plugins = with pkgs.tmuxPlugins; [
      sensible
      vim-tmux-navigator
      yank
    ];

    extraConfig = ''
      # True color support.
      set -ga terminal-overrides ",*256col*:Tc"

      # Reload config.
      bind r source-file ~/.config/tmux/tmux.conf \; display "Reloaded!"

      # Split keep current path.
      bind | split-window -h -c "#{pane_current_path}"
      bind - split-window -v -c "#{pane_current_path}"
      unbind '"'
      unbind %

      # Pane navigation with Alt+hjkl (also handled by vim-tmux-navigator).
      bind -n M-h select-pane -L
      bind -n M-j select-pane -D
      bind -n M-k select-pane -U
      bind -n M-l select-pane -R
    '';
  };
}
```

**Step 2: Wire + format + check + build + commit**

```nix
imports = [
  ./options.nix
  ./git.nix
  ./ssh.nix
  ./nix-settings.nix
  ./dev/cli-tools.nix
  ./dev/tmux.nix
  ./shell/zsh.nix
  ./shell/prompt.nix
];
```

```bash
nix run nixpkgs#nixfmt-rfc-style -- modules/dev/tmux.nix modules/default.nix
nix flake check --show-trace
nix build .#homeConfigurations.linux.activationPackage --show-trace
rm -f result
git add -A
git commit -m "feat: add tmux module with sensible defaults and plugins"
```

---

### Task 12: `modules/dev/kitty.nix` with absorbed `current-theme.conf`

**Goal:** Port the old kitty module; absorb `current-theme.conf` into the flake.

**Files:**

- Copy: `~/Downloads/repos/dotfiles/.config/kitty/current-theme.conf` → `modules/dev/kitty-theme.conf`
- Create: `modules/dev/kitty.nix`
- Modify: `modules/default.nix`

**Step 1: Copy the theme**

```bash
cp ~/Downloads/repos/dotfiles/.config/kitty/current-theme.conf modules/dev/kitty-theme.conf
```

**Step 2: Create `modules/dev/kitty.nix`**

```nix
{ ... }:

{
  programs.kitty = {
    enable = true;

    font = {
      name = "FiraCode Nerd Font";
      size = 12.5;
    };

    settings = {
      background_opacity = "0.87";
      dynamic_background_opacity = "yes";
      confirm_os_window_close = "0";
      enabled_layouts = "horizontal,stack";
      linux_display_server = "auto";

      cursor_trail = "1";
      cursor_trail_decay = "0.1 0.3";

      scrollback_pager_history_size = "500";
      scrollback_lines = "4000";
      wheel_scroll_min_lines = "1";

      enable_audio_bell = "no";
      window_padding_width = "3";

      allow_remote_control = "socket-only";
      listen_on = "unix:/tmp/kitty";
      shell_integration = "enabled";

      hide_window_decorations = "yes";

      include = "current-theme.conf";
    };

    keybindings = {
      "ctrl+shift+l" = "next_tab";
      "ctrl+shift+h" = "previous_tab";
      "ctrl+1" = "goto_tab 1";
      "ctrl+2" = "goto_tab 2";
      "ctrl+3" = "goto_tab 3";
      "ctrl+4" = "goto_tab 4";
      "ctrl+5" = "goto_tab 5";
      "ctrl+6" = "goto_tab 6";
      "ctrl+7" = "goto_tab 7";
      "ctrl+8" = "goto_tab 8";
      "ctrl+9" = "goto_tab 9";
      "ctrl+shift+f" = "toggle_layout stack";
      "alt+w" = "close_tab";
    };
  };

  xdg.configFile."kitty/current-theme.conf".source = ./kitty-theme.conf;
}
```

**Step 3: Wire + format + check + build + commit**

```nix
imports = [
  ./options.nix
  ./git.nix
  ./ssh.nix
  ./nix-settings.nix
  ./dev/cli-tools.nix
  ./dev/tmux.nix
  ./dev/kitty.nix
  ./shell/zsh.nix
  ./shell/prompt.nix
];
```

```bash
nix run nixpkgs#nixfmt-rfc-style -- modules/dev/kitty.nix modules/default.nix
nix flake check --show-trace
nix build .#homeConfigurations.linux.activationPackage --show-trace
rm -f result
git add -A
git commit -m "feat: add kitty module with absorbed current-theme.conf"
```

---

### Task 13: `modules/dev/neovim/` — absorb the nvim config + wire module

**Goal:** Bring the nvim config into the flake. Future iteration is infrequent (user stated ~annual).

**Files:**

- Copy: contents of `~/Downloads/repos/dotfiles/.config/nvim/` → `modules/dev/neovim/`
- Create: `modules/dev/neovim.nix`
- Modify: `modules/default.nix`

**Step 1: Copy nvim config**

```bash
cp -R ~/Downloads/repos/dotfiles/.config/nvim modules/dev/neovim
ls modules/dev/neovim
```

Expected: `init.lua`, `lua/`, `after/`, possibly `test.py`, `.stow-local-ignore`, `.stylua.toml`, `LICENSE`, `README.md`.

Remove the local-ignore and bak/undodir (runtime state, not config):

```bash
rm -rf modules/dev/neovim/.stow-local-ignore modules/dev/neovim/.undodir
# Keep .stylua.toml, LICENSE, README, test.py (harmless).
```

**Step 2: Create `modules/dev/neovim.nix`**

```nix
{ pkgs, ... }:

{
  programs.neovim = {
    enable = true;
    viAlias = true;
    vimAlias = true;
    defaultEditor = true;
  };

  xdg.configFile."nvim".source = ./neovim;
}
```

NOTE: We use `xdg.configFile."nvim".source = ./neovim` instead of the old `home.file.".config/nvim".source = "${dotfiles}/..."`. Nix hashes the directory; HM writes it into the Nix store and symlinks `~/.config/nvim` to it.

**Step 3: Wire + format + check + build + commit**

```nix
imports = [
  ./options.nix
  ./git.nix
  ./ssh.nix
  ./nix-settings.nix
  ./dev/cli-tools.nix
  ./dev/tmux.nix
  ./dev/kitty.nix
  ./dev/neovim.nix
  ./shell/zsh.nix
  ./shell/prompt.nix
];
```

```bash
nix run nixpkgs#nixfmt-rfc-style -- modules/dev/neovim.nix modules/default.nix
nix flake check --show-trace
nix build .#homeConfigurations.linux.activationPackage --show-trace
rm -f result
git add -A
git commit -m "feat: absorb neovim config and add neovim module"
```

---

### Task 14: `modules/platform/linux.nix` and `modules/platform/darwin.nix` + platform switch in `default.nix`

**Goal:** Real platform-specific handling. Linux gets the `chsh` activation hook (ported from old `home.nix`) and the 1Password Linux agent socket. Darwin gets the macOS agent socket path.

**Files:**

- Create: `modules/platform/linux.nix`
- Create: `modules/platform/darwin.nix`
- Modify: `modules/default.nix` (conditional imports)

**Step 1: Create `modules/platform/linux.nix`**

```nix
{ config, lib, pkgs, ... }:

{
  # 1Password SSH agent socket (Linux).
  programs.ssh.extraConfig = ''
    Host *
      IdentityAgent ~/.1password/agent.sock
  '';

  # One-shot: make zsh the login shell if it isn't already.
  home.activation.make-zsh-default-shell =
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
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
```

**Step 2: Create `modules/platform/darwin.nix`**

```nix
{ ... }:

{
  programs.ssh.extraConfig = ''
    Host *
      IdentityAgent "~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
  '';
}
```

**Step 3: Update `modules/default.nix` for platform conditional**

```nix
{ pkgs, lib, ... }:

{
  imports = [
    ./options.nix
    ./git.nix
    ./ssh.nix
    ./nix-settings.nix
    ./dev/cli-tools.nix
    ./dev/tmux.nix
    ./dev/kitty.nix
    ./dev/neovim.nix
    ./shell/zsh.nix
    ./shell/prompt.nix
  ]
  ++ lib.optionals pkgs.stdenv.isLinux [ ./platform/linux.nix ]
  ++ lib.optionals pkgs.stdenv.isDarwin [ ./platform/darwin.nix ];
}
```

**Step 4: Format + check + build + commit**

```bash
nix run nixpkgs#nixfmt-rfc-style -- modules/platform/linux.nix modules/platform/darwin.nix modules/default.nix
nix flake check --show-trace
nix build .#homeConfigurations.linux.activationPackage --show-trace
nix build .#homeConfigurations.mac.activationPackage --show-trace
rm -f result
git add -A
git commit -m "feat: add platform modules for Linux and Darwin"
```

NOTE: Darwin build may fail on Linux if nixpkgs hasn't cached aarch64-darwin evaluation. If you get an error like `a 'aarch64-darwin' with features {} is required`, skip the `mac` build — it will work on an actual Mac. Commit anyway.

---

### Task 15: Unfree package allowance

**Goal:** Port the `allowUnfreePredicate` pattern so we can introduce proprietary packages later without surprise. Empty list for now.

**Files:**

- Create: `modules/unfree.nix`
- Modify: `modules/default.nix`

**Step 1: Create `modules/unfree.nix`**

```nix
{ lib, ... }:

{
  nixpkgs.config.allowUnfreePredicate =
    pkg:
    builtins.elem (lib.getName pkg) [
      # Add package names here when proprietary packages are introduced.
    ];
}
```

**Step 2: Wire in `modules/default.nix`**

```nix
imports = [
  ./options.nix
  ./unfree.nix
  # ... rest
]
++ lib.optionals pkgs.stdenv.isLinux [ ./platform/linux.nix ]
++ lib.optionals pkgs.stdenv.isDarwin [ ./platform/darwin.nix ];
```

**Step 3: Format + check + build + commit**

```bash
nix run nixpkgs#nixfmt-rfc-style -- modules/unfree.nix modules/default.nix
nix flake check --show-trace
nix build .#homeConfigurations.linux.activationPackage --show-trace
rm -f result
git add -A
git commit -m "feat: add unfree allowance stub (empty for now)"
```

---

## Phase 3 — Cutover (Task 16)

### Task 16: Back up dotfiles, remove conflicting symlinks, activate

**Goal:** One-time cutover from manual dotfiles to home-manager-managed files.

**This task involves irreversible-feeling operations. STOP and read before executing.**

**Files affected (outside the flake):**

- Backup: `~/.zshrc`, `~/.zshrc.local`, `~/.zshenv`, `~/.gitconfig`, `~/.bashrc`, `~/.profile` to `~/.backup-pre-hm-<date>/`
- Delete (they're symlinks into dotfiles): `~/.config/nvim`, `~/.config/kitty`, `~/.config/tmux`, `~/.config/oh-my-posh`
- Activate: home-manager generation

**Step 1: Pre-flight — confirm token rotation is done**

```bash
grep -iE 'token|SRC_ACCESS' ~/.zshrc.local 2>/dev/null || echo "ok: no token in .zshrc.local"
```

If any token matches, STOP. Rotate the Sourcegraph token in 1Password first; confirm with the user before continuing.

**Step 2: Backup**

```bash
BACKUP_DIR="$HOME/.backup-pre-hm-$(date +%Y%m%d)"
mkdir -p "$BACKUP_DIR"
for f in .zshrc .zshrc.local .zshenv .gitconfig .bashrc .profile; do
  [ -e "$HOME/$f" ] && cp -a "$HOME/$f" "$BACKUP_DIR/"
done
[ -e "$HOME/.ssh/config" ] && cp -a "$HOME/.ssh/config" "$BACKUP_DIR/ssh-config"
echo "Backed up to $BACKUP_DIR"
ls -la "$BACKUP_DIR"
```

Expected: backup dir listed with the files. Any unexpected emptiness means the original wasn't there — that's fine.

**Step 3: Remove conflicting symlinks**

```bash
for link in ~/.config/nvim ~/.config/kitty ~/.config/tmux ~/.config/oh-my-posh; do
  if [ -L "$link" ]; then
    echo "Removing symlink: $link -> $(readlink "$link")"
    rm "$link"
  elif [ -e "$link" ]; then
    echo "WARNING: $link exists but is not a symlink. Backing up instead."
    mv "$link" "$BACKUP_DIR/$(basename "$link")"
  fi
done
```

**Step 4: Activate home-manager**

```bash
cd ~/Downloads/repos/home-manager
nix run home-manager/master -- switch --flake .#linux --show-trace
```

Expected: activation message, new generation number printed. If activation fails with "file already exists" errors, back up the listed files and retry.

**Step 5: Verify from a fresh shell**

Open a new terminal window (or `exec zsh -l`):

```bash
which zsh bat eza fd fzf zoxide
echo "--- git ---"
git config --global --get user.name
git config --global --get user.email
echo "--- prompt (visual)"
# Your prompt should render via oh-my-posh.
echo "--- aliases"
alias vim ll cd cat
```

Expected: all tools resolve to `/home/jirizarry/.nix-profile/bin/...`. Git shows `julian-irizarry` and your personal email. Aliases present. Prompt looks the same as before.

**Step 6: Commit — no flake changes expected; this task is operational**

Nothing to commit unless you edited a flake file to fix something. If you did, commit.

---

## Phase 4 — Extended flake (separate repo)

The extended (work) flake lives in a separate repo on GHE and is out of scope for this plan. It will consume `homeModules.default` from this flake and add:

- `work-identity.nix` — sets `my.git.userEmail`, `signingKey`, `extraIncludes`
- `work-secrets.nix` — `my.zsh.extraInitFragments` with `op read` invocations
- `work-ssh.nix` — `my.ssh.extraHosts` for `mimosa-dev`, `mimosa-dev-arm`
- `work-aliases.nix` — `wpc`, `wpd`, `scs` aliases via `my.zsh.extraInitFragments`
- `work-packages.nix` — internal CLIs from nixpkgs or an overlay, if available

A separate implementation plan will be written for that repo. Final verification of this plan happens after that plan is executed on the work machine.

---

## Verification — full plan complete

When Task 16 succeeds and a fresh shell shows all tools working:

1. Run `nix flake check` one last time.
2. Push: `git push origin main` (GCM triggers browser auth on first push).
3. Design doc and plan are committed and pushed along with code.
4. Proceed to writing the extended flake plan in a separate session.

## Rollback

If cutover breaks the shell:

**Soft (preferred):**

```bash
home-manager generations
home-manager switch --switch-generation <previous>
```

**Nuclear:**

```bash
# Remove home-manager managed files
rm -rf ~/.local/state/home-manager ~/.config/home-manager

# Restore backups
cp -a ~/.backup-pre-hm-<date>/.* ~/ 2>/dev/null

# Re-point dotfiles symlinks if you want the old setup back
ln -s ~/Downloads/repos/dotfiles/.config/nvim ~/.config/nvim
# repeat for kitty, tmux, oh-my-posh
```

## Notes for the executing engineer

- **Never activate (`home-manager switch`) before Task 16.** Use `build` for intermediate verification.
- **Commit after every task.** If `nix flake check` or `home-manager build` fails mid-task, fix before committing.
- **If a task refers to `nixfmt` and nixfmt isn't installed:** `nix profile install nixpkgs#nixfmt-rfc-style` (one-time).
- **If `nix fmt` doesn't work:** fall back to `nix run nixpkgs#nixfmt-rfc-style -- <files>`.
- **If the Darwin build fails** because the eval machine can't produce an `aarch64-darwin` closure, that's OK for this Linux execution context — just verify `.#linux` and commit.
- **If `home-manager` CLI is missing entirely:** the plan uses `nix run home-manager/master -- ...` everywhere, so no install is required. If you prefer an installed HM, `nix profile install home-manager` is fine but not necessary.
- **If any task's build fails with "option X does not exist":** the option name changed in a recent HM release. Check HM release notes. Common renames: `initExtra` → `initContent` (zsh); `programs.git.settings` (old) → direct keys (new). Adjust and continue.
- **Do not add features beyond what the plan specifies.** If something looks wrong, pause and ask.
