import { useEffect, useMemo, useState } from "react";
import {
  Action,
  ActionPanel,
  Icon,
  List,
  useNavigation,
  showToast,
  Toast,
} from "@vicinae/api";
import { readdirSync } from "fs";
import { getBackend, type TerminalBackend } from "./backends";
import { loadConfig, type Config } from "./config";
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
  const { push, pop } = useNavigation();

  useEffect(() => {
    getBackend(cfg.terminal).then(setBackend);
  }, [cfg.terminal]);

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
      searchBarPlaceholder={`Search under ${activeRoot.replace(homedir(), "~") || "…"}`}
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
                  title="Open Shell in Kitty"
                  icon={Icon.Terminal}
                  onAction={async () => {
                    if (!backend) return;
                    try {
                      await backend.openSession(e.name, e.path);
                      await showToast({
                        title: `Opened ${e.name}`,
                        style: Toast.Style.Success,
                      });
                    } catch (err) {
                      await showToast({
                        title: "Error",
                        message: String(err),
                        style: Toast.Style.Failure,
                      });
                    }
                  }}
                />
                <Action
                  title="Open Neovim in Kitty"
                  icon={Icon.Pencil}
                  shortcut={{ modifiers: ["cmd"], key: "return" }}
                  onAction={async () => {
                    if (!backend) return;
                    try {
                      await backend.openSession(e.name, e.path, ["nvim"]);
                      await showToast({
                        title: `Opened ${e.name}`,
                        style: Toast.Style.Success,
                      });
                    } catch (err) {
                      await showToast({
                        title: "Error",
                        message: String(err),
                        style: Toast.Style.Failure,
                      });
                    }
                  }}
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
