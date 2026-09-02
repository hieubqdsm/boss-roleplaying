extends Node

## EventBus — autoload bus signal thuần, không chứa state (docs/CODING.md §5).
## Chỉ dùng cho event thật sự cross-cutting; quan hệ 1:1 thì truyền tham chiếu.

signal round_changed(round_idx: int, max_rounds: int)
signal fight_ended(victory: bool, stats: Dictionary)
