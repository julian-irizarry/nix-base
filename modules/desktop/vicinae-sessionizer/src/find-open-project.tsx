import { useEffect, useState } from "react";
import {
  Action,
  ActionPanel,
  Icon,
  List,
  showToast,
  Toast,
  closeMainWindow,
} from "@vicinae/api";
import { basename } from "path";
import { loadConfig } from "./config";
import { getBackend, type TerminalBackend, type OpenProject } from "./backends";
import { log } from "./log";

export default function FindOpenProject() {
  const [cfg] = useState(() => loadConfig());
  const [backend, setBackend] = useState<TerminalBackend | null>(null);
  const [items, setItems] = useState<OpenProject[]>([]);

  useEffect(() => {
    (async () => {
      log.info("find-open", "init", {
        terminal: cfg.terminal,
        roots: cfg.roots,
      });
      const b = await getBackend(cfg.terminal);
      setBackend(b);
      try {
        const projects = await b.listOpenProjects(cfg.roots);
        log.info("find-open", "listed", { count: projects.length });
        setItems(projects);
      } catch (err) {
        log.error("find-open", "listOpenProjects threw", { err: String(err) });
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
    log.info("find-open", "focus", {
      terminal: cfg.terminal,
      clientId: p.clientId,
      workspace: p.workspace,
      cwd: p.cwd,
    });
    try {
      await backend.focusProject(p);
      await closeMainWindow();
    } catch (err) {
      log.error("find-open", "focus failed", { err: String(err) });
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
          title={p.workspace ?? basename(p.cwd)}
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
