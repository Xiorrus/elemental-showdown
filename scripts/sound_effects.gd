# sound_effects.gd
# Procedural SFX engine and Audio player pool for Elemental Showdown.
# Synthesizes crisp 16-bit PCM waveforms for elemental impacts, critical hits,
# blocks, heals, and UI clicks on-demand. Zero external audio asset dependencies.
extends Node

const SAMPLE_RATE = 22050
const MAX_AUDIO_PLAYERS = 8

var _players: Array[AudioStreamPlayer] = []
var _player_idx: int = 0
var _cache: Dictionary = {}

func _ready():
	_init_player_pool()
	_preheat_audio()

func _init_player_pool():
	for i in range(MAX_AUDIO_PLAYERS):
		var p = AudioStreamPlayer.new()
		p.name = "SFX_Player_%d" % i
		p.bus = "SFX" if AudioServer.get_bus_index("SFX") != -1 else "Master"
		add_child(p)
		_players.append(p)

func _preheat_audio():
	# Pre-generate standard combat and elemental streams
	get_stream("hit")
	get_stream("fire")
	get_stream("water")
	get_stream("earth")
	get_stream("air")
	get_stream("crit")
	get_stream("block")
	get_stream("heal")
	get_stream("click")

func play_sfx(sfx_name: String, volume_db: float = 0.0, pitch_scale: float = 1.0):
	if _players.is_empty():
		return
	var stream = get_stream(sfx_name)
	if stream == null:
		return

	var p = _players[_player_idx]
	_player_idx = (_player_idx + 1) % _players.size()

	p.stream = stream
	p.volume_db = volume_db
	p.pitch_scale = pitch_scale * randf_range(0.96, 1.04) # Slight organic variance
	p.play()

func play_element_impact(elem: String, is_crit: bool = false, is_weakness: bool = false):
	var key = elem.to_lower()
	var pitch = 1.0
	var vol = 0.0

	if is_crit:
		vol += 2.0
		pitch *= 1.10
		play_sfx("crit", 1.5, 1.05)

	if is_weakness:
		vol += 1.5
		pitch *= 1.05

	match key:
		"fire", "steam", "magma":
			play_sfx("fire", vol, pitch)
		"water", "ice", "mist", "mud":
			play_sfx("water", vol, pitch)
		"earth", "dust", "sand":
			play_sfx("earth", vol + 1.0, pitch * 0.95)
		"air", "vacuum", "sound":
			play_sfx("air", vol, pitch * 1.05)
		"plasma", "lightning":
			play_sfx("plasma", vol, pitch)
		"space":
			play_sfx("space", vol, pitch)
		"time":
			play_sfx("time", vol, pitch)
		_:
			play_sfx("hit", vol, pitch)

func get_stream(sfx_name: String) -> AudioStreamWAV:
	if _cache.has(sfx_name):
		return _cache[sfx_name]

	var stream = _synthesize_waveform(sfx_name)
	if stream:
		_cache[sfx_name] = stream
	return stream

func _synthesize_waveform(sfx_name: String) -> AudioStreamWAV:
	var duration: float = 0.20
	var num_samples: int = int(SAMPLE_RATE * duration)

	match sfx_name:
		"fire":
			duration = 0.26
		"water":
			duration = 0.28
		"earth":
			duration = 0.32
		"air":
			duration = 0.22
		"plasma":
			duration = 0.24
		"space":
			duration = 0.35
		"time":
			duration = 0.25
		"crit":
			duration = 0.35
		"block":
			duration = 0.20
		"heal":
			duration = 0.38
		"click":
			duration = 0.05
		"hit":
			duration = 0.18
		_:
			duration = 0.20

	num_samples = int(SAMPLE_RATE * duration)
	var byte_data = PackedByteArray()
	byte_data.resize(num_samples * 2) # 16-bit mono = 2 bytes per sample

	for i in range(num_samples):
		var t = float(i) / float(num_samples) # 0.0 to 1.0
		var sec = float(i) / float(SAMPLE_RATE)
		var val: float = 0.0

		match sfx_name:
			"fire":
				# Explosive pop + crackle noise burst
				var pop_freq = lerp(160.0, 70.0, t)
				var pop = sin(2.0 * PI * pop_freq * sec)
				var noise = randf_range(-1.0, 1.0)
				var crackle = (randf_range(-1.0, 1.0) * 0.8) if (randf() < 0.15) else 0.0
				var env = pow(1.0 - t, 1.8)
				val = (pop * 0.55 + noise * 0.30 + crackle * 0.15) * env

			"water":
				# High crystalline ice shatter + fluid sine sweep
				var f1 = lerp(1800.0, 700.0, t)
				var f2 = lerp(2600.0, 1200.0, t)
				var sine1 = sin(2.0 * PI * f1 * sec)
				var sine2 = sin(2.0 * PI * f2 * sec)
				var splash = randf_range(-0.25, 0.25) * (1.0 - t)
				var env = pow(1.0 - t, 1.5)
				val = (sine1 * 0.45 + sine2 * 0.35 + splash * 0.20) * env

			"earth":
				# Heavy tectonic sub-bass rumble + rocky crunch
				var rumble_freq = lerp(85.0, 38.0, t)
				var rumble = sin(2.0 * PI * rumble_freq * sec)
				var crunch = randf_range(-0.5, 0.5) if t < 0.45 else randf_range(-0.2, 0.2)
				var env = 1.0 - pow(t, 0.8)
				val = (rumble * 0.65 + crunch * 0.35) * env

			"air":
				# Whipping blade slice & accelerating whoosh
				var sweep_freq = 400.0 + 800.0 * sin(PI * t)
				var sine = sin(2.0 * PI * sweep_freq * sec)
				var noise = randf_range(-0.5, 0.5) * sin(PI * t)
				var env = pow(1.0 - t, 1.3)
				val = (sine * 0.35 + noise * 0.65) * env

			"plasma":
				# High-voltage electric arc & bitcrushed buzz
				var freq = lerp(580.0, 180.0, t)
				var phase = fmod(sec * freq, 1.0)
				var sqr = 1.0 if phase > 0.48 else -1.0
				var zap_noise = randf_range(-0.4, 0.4)
				var env = pow(1.0 - t, 2.0)
				val = (sqr * 0.6 + zap_noise * 0.4) * env

			"space":
				# Cosmic warp resonance with dual harmonic shimmer
				var f1 = 320.0 + 120.0 * sin(PI * t * 2.0)
				var f2 = 640.0 + 240.0 * cos(PI * t * 2.0)
				var sine = sin(2.0 * PI * f1 * sec) * 0.5 + sin(2.0 * PI * f2 * sec) * 0.5
				var env = sin(PI * t)
				val = sine * env

			"time":
				# Crisp dual clockwork tick with rapid decay
				var tick_phase = fmod(sec * 18.0, 1.0)
				var tick = sin(2.0 * PI * 1800.0 * sec) * exp(-tick_phase * 12.0)
				var env = pow(1.0 - t, 1.4)
				val = tick * env

			"crit":
				# Resonant metallic cleave & bright bell ping
				var b1 = sin(2.0 * PI * 1320.0 * sec)
				var b2 = sin(2.0 * PI * 2640.0 * sec)
				var clang = sin(2.0 * PI * 440.0 * sec) * pow(1.0 - t, 3.0)
				var env = pow(1.0 - t, 1.2)
				val = (b1 * 0.5 + b2 * 0.3 + clang * 0.2) * env

			"block":
				# Heavy iron shield deflection clang
				var clang1 = sin(2.0 * PI * 480.0 * sec)
				var clang2 = sin(2.0 * PI * 860.0 * sec)
				var impact = randf_range(-0.3, 0.3) if t < 0.25 else 0.0
				var env = pow(1.0 - t, 2.6)
				val = (clang1 * 0.55 + clang2 * 0.30 + impact * 0.15) * env

			"heal":
				# Gentle arpeggiated tri-tone chime (C5 -> E5 -> G5)
				var note_f = 523.25
				if t > 0.33 and t <= 0.66:
					note_f = 659.25
				elif t > 0.66:
					note_f = 783.99
				var chime = sin(2.0 * PI * note_f * sec)
				var env = 1.0 - t
				val = chime * 0.7 * env

			"click":
				# Crisp UI button press / form switch click
				var click_freq = lerp(950.0, 400.0, t)
				var blip = sin(2.0 * PI * click_freq * sec)
				val = blip * (1.0 - t)

			"hit", _:
				# Punchy kinetic impact thud
				var punch_freq = lerp(220.0, 50.0, t)
				var punch = sin(2.0 * PI * punch_freq * sec)
				var snap = randf_range(-0.35, 0.35) if t < 0.20 else 0.0
				var env = pow(1.0 - t, 2.2)
				val = (punch * 0.70 + snap * 0.30) * env

		val = clamp(val, -1.0, 1.0)
		var sample_16 = int(round(val * 32767.0))
		byte_data.encode_s16(i * 2, sample_16)

	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	stream.data = byte_data
	return stream
