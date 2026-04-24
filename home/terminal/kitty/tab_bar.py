import datetime
import os
import re
from kitty.boss import get_boss
from kitty.fast_data_types import Screen, add_timer
from kitty.tab_bar import (
    DrawData,
    ExtraData,
    TabBarData,
    as_rgb,
    draw_title,
)

# Nerd Font icons (using proper Unicode codepoints, not UTF-16 surrogates)
ICON_NVIM = "\ue6ae"           # nf-custom-neovim
ICON_SSH = "\U000F048B"       # nf-md-server 󰒋
ICON_PYTHON = "\ue73c"
ICON_NODE = "\ue718"
ICON_ZOOM = " \uf848"
ICON_TERMINAL = "\uf489"
ICON_CLOCK = "\uf017"         # nf-fa-clock_o
ICON_COMPUTER = "\uf108"      # nf-fa-desktop

# Powerline separator
SEP_RIGHT = "\ue0b0"  # ▶
SEP_LEFT = "\ue0b2"   # ◀

# Colors
ACTIVE_BG = 0x26233A
ACTIVE_FG = 0xFFFFFF
INACTIVE_BG = 0x000000
INACTIVE_FG = 0xBAB8C8
BAR_BG = 0x000000
ACCENT = 0xFF9DA4
TERMINAL_ORANGE = 0xFAB387
NVIM_GREEN = 0xA6E3A1
SSH_PINK = 0xF5C2E7
STATUS_FG = 0x908CAA

ICON_DOCKER = "\uf308"         # nf-linux-docker
ICON_GIT = "\ue702"            # nf-dev-git
ICON_RUST = "\ue7a8"           # nf-dev-rust
ICON_GO = "\ue626"             # nf-seti-go
ICON_RUBY = "\ue739"           # nf-dev-ruby
ICON_LUA = "\ue620"            # nf-seti-lua
ICON_JAVA = "\ue738"           # nf-dev-java
ICON_HTOP = "\uf080"           # nf-fa-bar_chart
ICON_MAN = "\uf15c"            # nf-fa-file_text
ICON_NIX = "\uf2dc"            # nf-fa-snowflake_o

PROCESS_ICONS = {
    "nvim": (ICON_NVIM, NVIM_GREEN),
    "vim": (ICON_NVIM, NVIM_GREEN),
    "ssh": (ICON_SSH, SSH_PINK),
    "python": (ICON_PYTHON, 0xF6C177),
    "python3": (ICON_PYTHON, 0xF6C177),
    "python3.12": (ICON_PYTHON, 0xF6C177),
    "python3.13": (ICON_PYTHON, 0xF6C177),
    "node": (ICON_NODE, 0x9CCFD8),
    "docker": (ICON_DOCKER, 0x89B4FA),
    "docker-compose": (ICON_DOCKER, 0x89B4FA),
    "git": (ICON_GIT, 0xFAB387),
    "lazygit": (ICON_GIT, 0xFAB387),
    "cargo": (ICON_RUST, 0xFAB387),
    "rustc": (ICON_RUST, 0xFAB387),
    "go": (ICON_GO, 0x89DCEB),
    "ruby": (ICON_RUBY, 0xF38BA8),
    "irb": (ICON_RUBY, 0xF38BA8),
    "lua": (ICON_LUA, 0x89B4FA),
    "luajit": (ICON_LUA, 0x89B4FA),
    "java": (ICON_JAVA, 0xF38BA8),
    "htop": (ICON_HTOP, 0xA6E3A1),
    "btop": (ICON_HTOP, 0xA6E3A1),
    "top": (ICON_HTOP, 0xA6E3A1),
    "man": (ICON_MAN, 0xCDD6F4),
    "nix": (ICON_NIX, 0x89B4FA),
    "nix-shell": (ICON_NIX, 0x89B4FA),
    "nix-build": (ICON_NIX, 0x89B4FA),
    "nix-env": (ICON_NIX, 0x89B4FA),
}

HOSTNAME = "local"

timer_id = None


def _redraw_tab_bar(timer_id_unused):
    boss = get_boss()
    if boss:
        for tm in boss.os_window_map.values():
            tm.mark_tab_bar_dirty()


def _get_tab_obj(tab_data):
    boss = get_boss()
    if not boss:
        return None
    for tm in boss.os_window_map.values():
        for t in tm.tabs:
            if t.id == tab_data.tab_id:
                return t
    return None


def _get_process_name(tab_obj):
    if not tab_obj:
        return ""
    try:
        exe = tab_obj.get_exe_of_active_window()
        if exe:
            name = os.path.basename(exe)
            if name == "ssh":
                return "ssh"
            return name
    except Exception:
        pass
    return ""


def _is_ssh_session(tab_obj):
    """Check if this tab is running SSH, even if the foreground process changed."""
    if not tab_obj:
        return False
    try:
        exe = tab_obj.get_exe_of_active_window()
        if exe and os.path.basename(exe) == "ssh":
            return True
        # Also check cmdline of the active window for ssh
        w = tab_obj.active_window
        if w and w.child:
            cmdline = w.child.cmdline
            if cmdline and os.path.basename(cmdline[0]) == "ssh":
                return True
    except Exception:
        pass
    return False


def _get_ssh_host(tab_obj):
    """Extract SSH hostname from cmdline args first, then fall back to title parsing."""
    if not tab_obj:
        return "ssh"
    try:
        # Try to get hostname from the ssh command arguments
        w = tab_obj.active_window
        if w and w.child:
            cmdline = w.child.cmdline or []
            # Parse ssh args: look for the hostname (first non-flag argument after "ssh")
            found_ssh = False
            for arg in cmdline:
                if not found_ssh:
                    if os.path.basename(arg) == "ssh":
                        found_ssh = True
                    continue
                # Skip flags like -p, -i, -o, etc.
                if arg.startswith("-"):
                    continue
                # This should be [user@]hostname
                if "@" in arg:
                    return arg.split("@", 1)[1]
                return arg
    except Exception:
        pass

    # Fall back to parsing the terminal title
    try:
        title = tab_obj.effective_title or tab_obj.title or ""
        match = re.search(r"@([\w\-._]+)", title)
        if match:
            return match.group(1)
        if title and not title.startswith("/") and not title.startswith("~"):
            match = re.match(r"^([\w\-._]+)", title)
            if match:
                host = match.group(1)
                if host not in ("ssh",):
                    return host
    except Exception:
        pass
    return "ssh"


def _get_cwd(tab_obj):
    if not tab_obj:
        return ""
    try:
        cwd = tab_obj.get_cwd_of_active_window()
        return cwd or ""
    except Exception:
        return ""


def _format_cwd(cwd, max_len=27, include_parent=False):
    if not cwd:
        return ""
    parts = cwd.rstrip("/").split("/")
    if include_parent and len(parts) >= 2:
        display = parts[-2] + "/" + parts[-1]
    else:
        display = parts[-1] if parts else cwd
    if len(display) > max_len:
        display = display[: max_len - 3] + "..."
    return display


def _is_zoomed(tab_data):
    return tab_data.num_windows > 1 and tab_data.layout_name == "stack"


def _draw_right_status(screen):
    now = datetime.datetime.now()
    time_str = now.strftime("%H:%M")
    # Cell widths (BMP nerd font icons are 1 cell wide)
    # Clock section: " [clock] [HH:MM] " = 1 + 1 + 1 + 5 + 1 = 9 cells
    # Domain section: " [computer] local " = 1 + 1 + 1 + 5 + 1 = 9 cells
    right_cells = 9 + 9
    cols = screen.columns
    gap = cols - screen.cursor.x - right_cells
    if gap > 0:
        screen.cursor.bg = as_rgb(BAR_BG)
        screen.draw(" " * gap)

    # Clock icon + time (same white-grey as inactive tabs)
    screen.cursor.bg = as_rgb(BAR_BG)
    screen.cursor.fg = as_rgb(INACTIVE_FG)
    screen.draw(" " + ICON_CLOCK + " " + time_str + " ")

    # Domain: computer icon + "local" (black bold text/icon on pink bg)
    screen.cursor.bg = as_rgb(ACCENT)
    screen.cursor.fg = as_rgb(0x000000)
    screen.cursor.bold = True
    screen.draw(" " + ICON_COMPUTER + " " + HOSTNAME + " ")
    screen.cursor.bold = False


def draw_tab(
    draw_data: DrawData,
    screen: Screen,
    tab: TabBarData,
    before: int,
    max_title_length: int,
    index: int,
    is_last: bool,
    extra_data: ExtraData,
) -> int:
    global timer_id
    if timer_id is None:
        timer_id = add_timer(_redraw_tab_bar, 30.0, True)

    is_active = tab.is_active

    if is_active:
        fg = as_rgb(ACTIVE_FG)
        bg = as_rgb(ACTIVE_BG)
    else:
        fg = as_rgb(INACTIVE_FG)
        bg = as_rgb(INACTIVE_BG)

    # Left separator: ◀ with tab bg as fg, bar bg as bg
    # (visible only on active tab since inactive bg = bar bg)
    screen.cursor.fg = bg
    screen.cursor.bg = as_rgb(BAR_BG)
    screen.draw(SEP_LEFT)

    screen.cursor.fg = fg
    screen.cursor.bg = bg
    screen.draw(" ")

    # Get real tab object for process/cwd info
    tab_obj = _get_tab_obj(tab)
    process_name = _get_process_name(tab_obj)

    is_ssh = process_name == "ssh" or _is_ssh_session(tab_obj)

    # Draw process icon (force SSH icon if detected via fallback)
    if is_ssh and process_name != "ssh":
        process_name = "ssh"
    icon_info = PROCESS_ICONS.get(process_name)
    if icon_info:
        icon, color = icon_info
        if is_active:
            screen.cursor.fg = as_rgb(color)
            screen.draw(icon)
            screen.cursor.fg = fg
        else:
            screen.draw(icon)
        screen.draw(" ")
    else:
        # Default: orange terminal icon
        if is_active:
            screen.cursor.fg = as_rgb(TERMINAL_ORANGE)
            screen.draw(ICON_TERMINAL)
            screen.cursor.fg = fg
        else:
            screen.draw(ICON_TERMINAL)
        screen.draw(" ")

    # Tab text: SSH hostname or cwd
    max_display = max_title_length - 4
    if max_display < 10:
        max_display = 10

    if is_ssh:
        host = _get_ssh_host(tab_obj)
        display = host or "ssh"
        if len(display) > max_display:
            display = display[: max_display - 3] + "..."
    else:
        cwd = _get_cwd(tab_obj)
        display = _format_cwd(cwd, max_len=max_display, include_parent=is_active)

    if display:
        screen.cursor.fg = fg
        screen.draw(display)
    else:
        draw_title(draw_data, screen, tab, index, max_title_length)

    # Zoom indicator (active tab only)
    if is_active and _is_zoomed(tab):
        screen.cursor.fg = as_rgb(ACCENT)
        screen.draw(ICON_ZOOM)
        screen.cursor.fg = fg

    screen.draw(" ")

    # Right separator: ▶ with tab bg as fg, bar bg as bg
    # (visible only on active tab since inactive bg = bar bg)
    screen.cursor.fg = bg
    screen.cursor.bg = as_rgb(BAR_BG)
    screen.draw(SEP_RIGHT)

    # Right status on last tab
    if is_last:
        _draw_right_status(screen)

    return screen.cursor.x
