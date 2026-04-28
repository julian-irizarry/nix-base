import { useEffect, useState } from "react";
import {
  Action,
  ActionPanel,
  Icon,
  List,
  showToast,
  Toast,
  closeMainWindow,
} from "./launcher";
import { loadConfig } from "./config";
import { getBackend, type TerminalBackend, type OpenSession } from "./backends";
import { log } from "./log";

export default function FindOpenSession() {
  const [cfg] = useState(() => loadConfig());
  const [backend, setBackend] = useState<TerminalBackend | null>(null);
  const [items, setItems] = useState<OpenSession[]>([]);

  useEffect(() => {
    (async () => {
      log.info("find-open", "init", { terminal: cfg.terminal });
      const b = await getBackend(cfg.terminal, cfg.terminalBin);
      setBackend(b);
      try {
        const sessions = await b.listOpenSessions();
        log.info("find-open", "listed", { count: sessions.length });
        setItems(sessions);
      } catch (err) {
        log.error("find-open", "listOpenSessions threw", { err: String(err) });
        await showToast({
          title: "Could not list open sessions",
          message: String(err),
          style: Toast.Style.Failure,
        });
      }
    })();
  }, [cfg.terminal]);

  const focus = async (s: OpenSession) => {
    if (!backend) return;
    log.info("find-open", "focus", {
      terminal: cfg.terminal,
      workspace: s.workspace,
    });
    try {
      await backend.focusSession(s);
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
    <List searchBarPlaceholder="Find open session…">
      {items.map((s) => (
        <List.Item
          key={s.workspace}
          title={s.workspace}
          icon={Icon.Folder}
          actions={
            <ActionPanel>
              <Action
                title="Focus"
                icon={Icon.ArrowRight}
                onAction={() => focus(s)}
              />
            </ActionPanel>
          }
        />
      ))}
    </List>
  );
}
