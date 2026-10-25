{ lib, ... }:

let
  mods = lib.attrNames (lib.filterAttrs (_: type: type == "directory") (builtins.readDir ./mods));
in
{
  # Claude Code mods (hooks-module plugins). The plugin-authoring skill writes
  # them under ~/.claude/dev-mods/<session-id>/, which only that session loads;
  # Claude Code auto-loads a plugin folder in ~/.claude/skills/ in every session
  # as <name>@skills-dir. The links are read-only store paths, so iterate on a
  # mod with `claude --plugin-dir home/cli/claude/mods/<name>` from the repo.
  # Claude Code generates .claude-plugin/types/ there for tsc; it's gitignored.
  home.file = lib.listToAttrs (
    map (name: lib.nameValuePair ".claude/skills/${name}" { source = ./mods + "/${name}"; }) mods
  );
}
