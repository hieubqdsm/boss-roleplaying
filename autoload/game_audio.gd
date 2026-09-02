extends Node

## GameAudio — phát nhạc/SFX toàn cục. Nhạc loop bằng stream.loop (OGG/MP3
## hỗ trợ runtime) + fallback nối lại khi finished.

const MUSIC_DIR := "res://assets/audio/music/"
const SFX_DIR := "res://assets/audio/sfx/"

const MUSIC_TRACKS := {
	"menu": MUSIC_DIR + "music_menu.ogg",
	"fight": MUSIC_DIR + "music_fight.mp3",
}

const SFX_TRACKS := {
	"ui_click": SFX_DIR + "ui_click.wav",
	"slash": SFX_DIR + "slash.wav",
	"bolt_cast": SFX_DIR + "bolt_cast.wav",
	"nova": SFX_DIR + "nova.wav",
	"hit_hero": SFX_DIR + "hit_hero.wav",
	"hurt_queen": SFX_DIR + "hurt_queen.wav",
	"hero_die": SFX_DIR + "hero_die.wav",
	"queen_die": SFX_DIR + "queen_die.wav",
	"round_start": SFX_DIR + "round_start.wav",
	"victory": SFX_DIR + "victory.wav",
	"defeat": SFX_DIR + "defeat.wav",
}

var _music: AudioStreamPlayer
var _sfx_pool: Array[AudioStreamPlayer] = []
var _sfx_cache: Dictionary = {}
var _current_track := ""


func _ready() -> void:
	_music = AudioStreamPlayer.new()
	_music.bus = "Music"
	add_child(_music)
	_music.finished.connect(func() -> void: _music.play())
	for i in 6:
		var p := AudioStreamPlayer.new()
		p.bus = "SFX"
		add_child(p)
		_sfx_pool.append(p)


func play_music(track: String) -> void:
	if track == _current_track and _music.playing:
		return
	if not MUSIC_TRACKS.has(track):
		push_warning("GameAudio: không có track nhạc '%s'" % track)
		return
	var stream: AudioStream = load(MUSIC_TRACKS[track])
	if stream == null:
		push_warning("GameAudio: không load được %s" % MUSIC_TRACKS[track])
		return
	if stream is AudioStreamOggVorbis:
		(stream as AudioStreamOggVorbis).loop = true
	elif stream is AudioStreamMP3:
		(stream as AudioStreamMP3).loop = true
	_music.stream = stream
	_music.play()
	_current_track = track


func stop_music() -> void:
	_music.stop()
	_current_track = ""


func play_sfx(name: String) -> void:
	if not SFX_TRACKS.has(name):
		push_warning("GameAudio: không có sfx '%s'" % name)
		return
	if not _sfx_cache.has(name):
		_sfx_cache[name] = load(SFX_TRACKS[name])
	var stream: AudioStream = _sfx_cache[name]
	if stream == null:
		return
	for p in _sfx_pool:
		if not p.playing:
			p.stream = stream
			p.play()
			return
	_sfx_pool[0].stream = stream
	_sfx_pool[0].play()
