extends Node

## GameSettings — tải/lưu cấu hình hiển thị & âm lượng (user://settings.cfg)
## và áp dụng lên window/bus ngay lập tức.
## Ghi chú policy: đây là config cross-cutting (không phải game-state), giữ
## tối thiểu theo docs/CODING.md §5 — không đụng state ván đấu.

const SETTINGS_PATH := "user://settings.cfg"
const SECTION := "settings"

signal settings_changed

var master_volume := 0.8
var music_volume := 0.6
var sfx_volume := 0.8
var fullscreen := false
var vsync := true


func _ready() -> void:
	load_settings()
	apply_settings()


func load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS_PATH) != OK:
		return
	master_volume = cfg.get_value(SECTION, "master_volume", master_volume)
	music_volume = cfg.get_value(SECTION, "music_volume", music_volume)
	sfx_volume = cfg.get_value(SECTION, "sfx_volume", sfx_volume)
	fullscreen = cfg.get_value(SECTION, "fullscreen", fullscreen)
	vsync = cfg.get_value(SECTION, "vsync", vsync)


func save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value(SECTION, "master_volume", master_volume)
	cfg.set_value(SECTION, "music_volume", music_volume)
	cfg.set_value(SECTION, "sfx_volume", sfx_volume)
	cfg.set_value(SECTION, "fullscreen", fullscreen)
	cfg.set_value(SECTION, "vsync", vsync)
	cfg.save(SETTINGS_PATH)


func apply_settings() -> void:
	_set_bus_volume(0, master_volume)
	_set_bus_volume(1, music_volume)
	_set_bus_volume(2, sfx_volume)
	DisplayServer.window_set_vsync_mode(
		DisplayServer.VSYNC_ENABLED if vsync else DisplayServer.VSYNC_DISABLED
	)
	var mode := DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED
	DisplayServer.window_set_mode(mode)
	settings_changed.emit()


func _set_bus_volume(bus_idx: int, linear: float) -> void:
	var db := -72.0 if linear <= 0.01 else linear_to_db(clampf(linear, 0.0, 1.0))
	AudioServer.set_bus_volume_db(bus_idx, db)
	AudioServer.set_bus_mute(bus_idx, linear <= 0.01)
