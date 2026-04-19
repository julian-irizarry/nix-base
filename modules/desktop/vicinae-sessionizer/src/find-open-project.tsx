import { useEffect, useState } from "react";
import {
  Action,
  ActionPanel,
  Icon,
  List,
  showToast,
  Toast,
} from "@vicinae/api";
import { execFile } from "child_process";
import { promisify } from "util";
import { basename } from "path";
import { homedir } from "os";
import { loadConfig } from "./config";
import { getBackend, type TerminalBackend, type OpenProject } from "./backends";

const execFileAsync = promisify(execFile);

export default function FindOpenProject() {
  const [cfg] = useState(() => loadConfig());
  const [backend, setBackend] = useState<TerminalBackend | null>(null);
  const [items, setItems] = useState<OpenProject[]>([]);

  useEffect(() => {
    (async () => {
      const b = await getBackend(cfg.terminal);
      setBackend(b);
      try {
        setItems(await b.listOpenProjects(cfg.roots));
      } catch (err) {
        await showToast({
          title: "Could not list open projects",
          message: String(err),
          style: Toast.Style.Failure,
        });
      }
    })();
  }, [cfg.terminal]);

  const focus = async (p: OpenProject) => {
    if (!backend) return;
    try {
      if (cfg.terminal === "wezterm" && p.clientId) {
        await execFileAsync("wezterm", [
          "cli",
          "activate-pane",
          "--pane-id",
          p.clientId,
        ]);
      } else if (cfg.terminal === "kitty" && p.clientId) {
        await execFileAsync("kitten", [
          "@",
          "--to",
          "unix:/tmp/kitty",
          "focus-tab",
          "--match",
          `id:${p.clientId}`,
        ]);
      }
    } catch (err) {
      await showToast({
        title: "Focus failed",
        message: String(err),
        style: Toast.Style.Failure,
      });
    }
  };

  return (
    <List searchBarPlaceholder="Find open project…">
      {items.map((p) => (
        <List.Item
          key={`${p.clientId ?? ""}::${p.cwd}`}
          title={basename(p.cwd)}
          subtitle={p.cwd.replace(homedir(), "~")}
          accessories={[{ text: p.workspace ?? `tab ${p.clientId ?? "?"}` }]}
          icon={Icon.Folder}
          actions={
            <ActionPanel>
              <Action
                title="Focus"
                icon={Icon.ArrowRight}
                onAction={() => focus(p)}
              />
            </ActionPanel>
          }
        />
      ))}
    </List>
  );
}
