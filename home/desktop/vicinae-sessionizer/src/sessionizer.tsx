import { useEffect, useMemo, useState } from "react";
import {
  Action,
  ActionPanel,
  Icon,
  List,
  useNavigation,
  showToast,
  Toast,
  closeMainWindow,
} from "@vicinae/api";
import { readdirSync } from "fs";
import { getBackend, type TerminalBackend } from "./backends";
import { loadConfig, type Config } from "./config";
import { loadMode, saveMode, type Mode } from "./mode";
import { log } from "./log";
import { homedir } from "os";
import { join, resolve } from "path";

// ─── Filesystem helpers ───────────────────────────────────────────────

interface Entry {
  name: string;
  path: string;
}

function listChildDirs(parent: string): Entry[] {
  try {
    return readdirSync(parent, { withFileTypes: true })
      .filter((d) => d.isDirectory() && !d.name.startsWith("."))
      .map((d) => ({ name: d.name, path: join(parent, d.name) }))
      .sort((a, b) => a.name.localeCompare(b.name));
  } catch {
    return [];
  }
}

// ─── Directory browser (for "Browse root…") ───────────────────────────

function Browser({
  start,
  onPick,
}: {
  start: string;
  onPick: (path: string) => void;
}) {
  const [current, setCurrent] = useState<string>(resolve(start));
  const entries = useMemo(() => listChildDirs(current), [current]);
  const parent = useMemo(() => {
    const up = resolve(current, "..");
    return up === current ? null : up;
  }, [current]);

  return (
    <List
      searchBarPlaceholder={`Browse under ${current}`}
      navigationTitle={current}
    >
      {parent ? (
        <List.Item
          title=".."
          subtitle={parent}
          icon={Icon.ArrowUp}
          actions={
            <ActionPanel>
              <Action
                title="Up"
                icon={Icon.ArrowUp}
                onAction={() => setCurrent(parent)}
              />
            </ActionPanel>
          }
        />
      ) : null}
      <List.Section title="Directories">
        {entries.map((e) => (
          <List.Item
            key={e.path}
            title={e.name}
            subtitle={e.path}
            icon={Icon.Folder}
            actions={
              <ActionPanel>
                <Action
                  title="Pick as Root"
                  icon={Icon.Checkmark}
                  onAction={() => onPick(e.path)}
                />
                <Action
                  title="Drill In"
                  icon={Icon.ArrowRight}
                  shortcut={{ modifiers: ["shift"], key: "return" }}
                  onAction={() => setCurrent(e.path)}
                />
              </ActionPanel>
            }
          />
        ))}
      </List.Section>
    </List>
  );
}

// ─── Main view ────────────────────────────────────────────────────────

export default function Sessionizer() {
  const [cfg] = useState<Config>(() => loadConfig());
  const [activeRoot, setActiveRoot] = useState<string>(cfg.roots[0] ?? "");
  const [backend, setBackend] = useState<TerminalBackend | null>(null);
  const [mode, setMode] = useState<Mode>(() => loadMode());
  const { push, pop } = useNavigation();

  useEffect(() => {
    log.info("sessionizer", "init", {
      terminal: cfg.terminal,
      roots: cfg.roots,
      mode,
    });
    getBackend(cfg.terminal).then(setBackend);
  }, [cfg.terminal]);

  const toggleMode = () => {
    const next: Mode = mode === "nvim" ? "shell" : "nvim";
    log.info("sessionizer", "mode toggled", { from: mode, to: next });
    setMode(next);
    saveMode(next);
  };
  const shell = process.env.SHELL ?? "/bin/sh";
  const cmd = mode === "nvim" ? [shell, "-lc", `nvim; exec ${shell} -l`] : [];

  const run = async (action: string, fn: () => Promise<void>) => {
    if (!backend) {
      log.warn("sessionizer", "action fired before backend ready", { action });
      return;
    }
    const start = Date.now();
    log.info("sessionizer", "action start", { action, mode });
    try {
      await fn();
      log.info("sessionizer", "action ok", { action, ms: Date.now() - start });
      await closeMainWindow();
    } catch (err) {
      log.error("sessionizer", "action failed", {
        action,
        ms: Date.now() - start,
        err: String(err),
      });
      await showToast({
        title: `${action} failed`,
        message: String(err),
        style: Toast.Style.Failure,
      });
    }
  };

  const entries = useMemo(() => {
    if (!activeRoot) return [];
    return listChildDirs(activeRoot);
  }, [activeRoot]);

  const onBrowse = () => {
    push(
      <Browser
        start={homedir()}
        onPick={(path) => {
          setActiveRoot(path);
          pop();
        }}
      />,
    );
  };

  const rootDropdown = (
    <List.Dropdown
      tooltip="Root directory"
      value={activeRoot}
      onChange={(val) => {
        if (val === "__browse__") {
          onBrowse();
          return;
        }
        setActiveRoot(val);
      }}
    >
      {cfg.roots.map((r) => (
        <List.Dropdown.Item
          key={r}
          title={r.replace(homedir(), "~")}
          value={r}
        />
      ))}
      <List.Dropdown.Item
        title="Browse…"
        value="__browse__"
        icon={Icon.MagnifyingGlass}
      />
    </List.Dropdown>
  );

  return (
    <List
      searchBarPlaceholder={`Search under ${activeRoot.replace(homedir(), "~") || "…"}${mode === "nvim" ? " (nvim)" : ""}`}
      searchBarAccessory={rootDropdown}
    >
      <List.Section title={activeRoot.replace(homedir(), "~")}>
        {entries.map((e) => (
          <List.Item
            key={e.path}
            title={e.name}
            subtitle={e.path}
            icon={Icon.Folder}
            actions={
              <ActionPanel>
                <Action
                  title="Add Tab"
                  icon={Icon.Terminal}
                  onAction={() =>
                    run("Add Tab", () => backend!.addTabToFocused(e.path, cmd))
                  }
                />
                <Action
                  title="Add Pane"
                  icon={Icon.AppWindowSidebarRight}
                  shortcut={{ modifiers: ["shift"], key: "return" }}
                  onAction={() =>
                    run("Add Pane", () =>
                      backend!.addPaneToFocused(e.path, cmd),
                    )
                  }
                />
                <Action
                  title="New Workspace"
                  icon={Icon.AppWindowList}
                  shortcut={{ modifiers: ["ctrl", "shift"], key: "return" }}
                  onAction={() =>
                    run("New Workspace", () =>
                      backend!.createWorkspace(e.name, e.path, cmd),
                    )
                  }
                />
                <Action
                  title={
                    mode === "nvim"
                      ? "Switch to Shell Mode"
                      : "Switch to Nvim Mode"
                  }
                  icon={Icon.Gear}
                  shortcut={{ modifiers: ["ctrl"], key: "e" }}
                  onAction={toggleMode}
                />
                <Action.CopyToClipboard
                  title="Copy Path"
                  shortcut={"copy-path"}
                  content={e.path}
                />
                <Action
                  title="Switch Root…"
                  icon={Icon.Folder}
                  shortcut={{ modifiers: ["cmd", "shift"], key: "r" }}
                  onAction={onBrowse}
                />
              </ActionPanel>
            }
          />
        ))}
      </List.Section>
    </List>
  );
}
