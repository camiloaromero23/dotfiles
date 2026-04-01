from enum import Enum
from kitty.fast_data_types import Screen, add_timer, get_boss, get_options
from kitty.tab_bar import DrawData, TabBarData, ExtraData, TabAccessor, as_rgb
from kitty.utils import color_as_int
import datetime
from pathlib import Path

opts = get_options()
CONFIG_DIR = Path(__file__).resolve().parent
SESSIONS_DIR = CONFIG_DIR / "sessions"

BG = as_rgb(color_as_int(opts.active_tab_background))
FG = as_rgb(color_as_int(opts.inactive_tab_foreground))
GREEN = as_rgb(color_as_int(opts.color2))

REFRESH_TIME = 5
SESSION_TABS_CACHE: dict[str, list[str]] = {}


def draw_text(screen: Screen, text: str, fg: int, *, bold: bool = False) -> None:
    screen.cursor.bg = BG
    screen.cursor.fg = fg
    screen.cursor.bold = bold
    screen.cursor.dim = False
    screen.cursor.italic = False
    screen.draw(text)


def get_session_name(max_size: int, tab: TabBarData) -> str | None:
    text = tab.session_name
    if not text:
        return None

    if len(text) <= max_size:
        return f" {text}"
    if max_size >= 1:
        return f" {text[:max_size]}..."
    return None


def get_time(max_size: int, tab: TabBarData) -> str | None:
    text = datetime.datetime.now().strftime("%a %b %d %H:%M ")
    if len(text) > max_size:
        return None
    return text


def get_session_tab_titles(session_name: str) -> list[str]:
    if session_name in SESSION_TABS_CACHE:
        return SESSION_TABS_CACHE[session_name]

    session_file = SESSIONS_DIR / f"{session_name}.session"
    titles: list[str] = []

    try:
        with session_file.open() as handle:
            for line in handle:
                if line.startswith("new_tab "):
                    title = line[len("new_tab ") :].strip()
                    if title:
                        titles.append(title)
    except OSError:
        pass

    SESSION_TABS_CACHE[session_name] = titles
    return titles


def get_preset_tab_title(tab: TabBarData, index: int) -> str | None:
    if tab.title.startswith("#"):
        return tab.title[1:]

    if not tab.session_name:
        return None

    titles = get_session_tab_titles(tab.session_name)
    if 0 < index <= len(titles):
        return titles[index - 1]

    return None


def get_tab(max_size: int, tab: TabBarData, index: int) -> str | None:
    accessor = TabAccessor(tab.tab_id)

    text = get_preset_tab_title(tab, index)
    if text is not None:
        pass
    else:
        text = Path(str(accessor.active_exe)).name
        text = text.lstrip(".-")

    if max_size <= len(text):
        return ""
    else:
        return text


def get_tab_label(tab: TabBarData, index: int) -> str:
    text = get_tab(10_000, tab, index)
    if not text:
        return str(index)
    return f"{index}:{text}"


def get_tab_label_for_width(tab: TabBarData, index: int, max_size: int) -> str | None:
    index_text = str(index)
    if max_size < len(index_text):
        return None

    text = get_tab(max_size, tab, index)
    if not text:
        label = index_text
    else:
        label = f"{index}:{text}"

    if len(label) <= max_size:
        return label
    if max_size >= len(index_text):
        return index_text
    return None


def labels_length(labels: list[str]) -> int:
    if not labels:
        return 0
    return sum(len(label) for label in labels) + len(labels) - 1


def center_labels(max_size: int) -> list[str]:
    labels = [get_tab_label(item["tab"], item["index"]) for item in center]
    if labels_length(labels) <= max_size:
        return labels

    active_item = center[active_index]
    active_label = get_tab_label_for_width(
        active_item["tab"], active_item["index"], max_size
    )
    if active_label is None:
        return []
    return [active_label]


def available_center_width(screen: Screen) -> int:
    right_text = get_time(screen.columns, center[active_index]["tab"]) or ""
    return max(0, screen.columns - len(right_text) - 2)


def redraw_tab_bar(_):
    tm = get_boss().active_tab_manager
    if tm is not None:
        tm.mark_tab_bar_dirty()


timer_id = None

center: list[dict[str, int | TabBarData]] = []
active_index = 0


class CenterStrategy(Enum):
    EXPAND_ALL = 0
    EXPAND_ACTIVE = 1
    NO_EXPAND = 2
    SHOW_ACTIVE = 3
    SHOW_ACTIVE_NO_EXPAND = 4


def center_strategy(screen: Screen) -> tuple[CenterStrategy, int]:
    max_size = available_center_width(screen)
    labels = [get_tab_label(item["tab"], item["index"]) for item in center]
    length = labels_length(labels)
    if length < max_size:
        return CenterStrategy.EXPAND_ALL, length

    active_item = center[active_index]
    active_label = get_tab_label(active_item["tab"], active_item["index"])
    if len(active_label) < max_size:
        return CenterStrategy.SHOW_ACTIVE, len(active_label)

    active_label = get_tab_label_for_width(
        active_item["tab"], active_item["index"], max_size
    )
    if active_label is None:
        return CenterStrategy.SHOW_ACTIVE_NO_EXPAND, 0
    return CenterStrategy.SHOW_ACTIVE_NO_EXPAND, len(active_label)


def draw_center(screen: Screen, strategy: CenterStrategy):
    labels = center_labels(available_center_width(screen))

    if strategy == CenterStrategy.EXPAND_ALL:
        for idx, label in enumerate(labels):
            if idx != 0:
                draw_text(screen, " ", FG)
            draw_text(
                screen,
                label,
                GREEN if idx == active_index else FG,
                bold=idx == active_index,
            )
        return

    if labels:
        draw_text(screen, labels[0], GREEN, bold=True)


def draw_left(screen: Screen, max_length: int):
    text = get_session_name(max_length, center[active_index]["tab"])
    if text:
        draw_text(screen, text, FG)


def draw_right(screen: Screen):
    max_size = screen.columns - screen.cursor.x
    text = get_time(max_size, center[active_index]["tab"])
    if not text:
        return
    draw_text(screen, " " * (max_size - len(text)), FG)
    draw_text(screen, text, FG)


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
    global center
    global timer_id
    global active_index

    if timer_id is None:
        timer_id = add_timer(redraw_tab_bar, REFRESH_TIME, True)
    if tab.is_active:
        active_index = index - 1

    center.append({"tab": tab, "index": index})

    # Draw everything on the last tab
    if is_last:
        screen.cursor.x = 0
        draw_text(screen, " " * screen.columns, FG)

        strategy, length = center_strategy(screen)

        center_start_position = (screen.columns - length) // 2
        screen.cursor.x = 0
        draw_left(screen, center_start_position - 1)

        screen.cursor.x = center_start_position
        draw_center(screen, strategy)

        draw_right(screen)
        center = []
    return screen.cursor.x
