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
import { execFileSync, spawn } from "child_process";
import { readdirSync, readFileSync, statSync, existsSync } from "fs";
import { homedir } from "os";
import { basename, join, resolve } from "path";

// ─── Config ────────────────────────────────────────────────────────────

// Roots are provided by the home-manager module via this JSON file,
// rendered from `my.vicinae.codeRoots`. If the file is missing (extension
// installed outside the nix flake, e.g. for development), fall back to
// $HOME/sources so the extension still works.
const ROOTS_FILE = join(
  homedir(),
  ".config",
  "vicinae",
  "sessionizer-roots.json",
);
const FALLBACK_ROOTS = [join(homedir(), "sources")];

function readConfiguredRoots(): string[] {
  try {
    const raw = readFileSync(ROOTS_FILE, "utf8");
    const parsed = JSON.parse(raw);
    if (Array.isArray(parsed) && parsed.every((r) => typeof r === "string")) {
      return parsed.map((r) => r.replace(/^~/, homedir())).filter(existsSync);
    }
  } catch {
    // no-op; fall through to fallback
  }
  return FALLBACK_ROOTS.filter(existsSync);
}

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

// ─── Kitty integration ────────────────────────────────────────────────

const KITTY_SOCKET = "unix:/tmp/kitty";

function focusTabByTitle(title: string): boolean {
  try {
    execFileSync(
      "kitten",
      ["@", "--to", KITTY_SOCKET, "focus-tab", "--match", `title:${title}`],
      { stdio: "ignore" },
    );
    return true;
  } catch {
    return false;
  }
}

function launchKittyTab(title: string, cwd: string, cmd: string[] = []) {
  const args = [
    "@",
    "--to",
    KITTY_SOCKET,
    "launch",
    "--type=tab",
    `--title=${title}`,
    `--cwd=${cwd}`,
    ...cmd,
  ];
  spawn("kitten", args, { detached: true, stdio: "ignore" }).unref();
}

async function openInKitty(entry: Entry, cmd: string[] = []) {
  const tabTitle = entry.name;
  if (focusTabByTitle(tabTitle)) {
    await showToast({
      title: `Focused ${tabTitle}`,
      style: Toast.Style.Success,
    });
    return;
  }
  launchKittyTab(tabTitle, entry.path, cmd);
  await showToast({
    title: `Opened ${tabTitle}`,
    style: Toast.Style.Success,
  });
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
  const [configured, setConfigured] = useState<string[]>([]);
  const [activeRoot, setActiveRoot] = useState<string>("");
  const { push, pop } = useNavigation();

  useEffect(() => {
    const roots = readConfiguredRoots();
    setConfigured(roots);
    if (roots.length > 0) {
      setActiveRoot(roots[0]);
    }
  }, []);

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
      {configured.map((r) => (
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
                  onAction={() => openInKitty(e)}
                />
                <Action
                  title="Open Neovim in Kitty"
                  icon={Icon.Pencil}
                  shortcut={{ modifiers: ["cmd"], key: "return" }}
                  onAction={() => openInKitty(e, ["nvim"])}
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
