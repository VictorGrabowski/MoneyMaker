## Tintements du bocal, fabriqués par calcul en attendant de vrais enregistrements :
## un son métallique par pièce (plus aigu pour les petites), un froissement pour les billets,
## un petit « pouf » pour les fusions. Huit sons au plus en même temps.
extends Node

const Denominations := preload("res://core/money/denominations.gd")

const MIX_RATE := 44100
const VOICES := 8
## Délai minimal entre deux sons : une pluie de pièces ne doit pas devenir un mur de bruit.
const MIN_GAP_MSEC := 35
## Fréquence fondamentale de chaque pièce, en hertz.
const COIN_PITCH: Dictionary = {
	1: 6400.0, 2: 5900.0, 5: 5300.0, 10: 5600.0, 20: 5100.0, 50: 4600.0, 100: 4300.0, 200: 3900.0,
}
const QUIET_DB := -34.0
const LOUD_DB := -16.0

var enabled := true
## Nombre de sons joués depuis le lancement (diagnostic).
var plays := 0

var _coin_streams: Dictionary = {}
var _bill_stream: AudioStreamWAV
var _merge_stream: AudioStreamWAV
var _players: Array[AudioStreamPlayer] = []
var _next_player := 0
var _last_play_msec := -1000


func _ready() -> void:
	for value in COIN_PITCH:
		_coin_streams[value] = _to_stream(_coin_samples(COIN_PITCH[value]))
	_bill_stream = _to_stream(_rustle_samples())
	_merge_stream = _to_stream(_pop_samples())
	for _i in VOICES:
		var player := AudioStreamPlayer.new()
		add_child(player)
		_players.append(player)


## Un objet touche quelque chose. `strength` : de 0 (frôlement) à 1 (chute franche).
func play_landing(value: int, strength: float) -> void:
	var stream: AudioStream = _coin_streams.get(value, _bill_stream)
	_play(stream, lerpf(QUIET_DB, LOUD_DB, clampf(strength, 0.0, 1.0)), randf_range(0.94, 1.06))


func play_merge() -> void:
	_play(_merge_stream, LOUD_DB, randf_range(0.96, 1.04))


func _play(stream: AudioStream, volume_db: float, pitch: float) -> void:
	var now := Time.get_ticks_msec()
	if not enabled or now - _last_play_msec < MIN_GAP_MSEC:
		return
	_last_play_msec = now
	var player := _players[_next_player]
	_next_player = (_next_player + 1) % VOICES
	player.stream = stream
	player.volume_db = volume_db
	player.pitch_scale = pitch
	player.play()
	plays += 1


## Tintement : quelques partiels inharmoniques qui s'éteignent vite, après un claquement très court.
func _coin_samples(frequency: float) -> PackedFloat32Array:
	var ratios: Array[float] = [1.0, 1.47, 2.09, 2.92]
	var levels: Array[float] = [1.0, 0.55, 0.32, 0.18]
	var decays: Array[float] = [22.0, 28.0, 36.0, 46.0]
	var count := int(MIX_RATE * 0.22)
	var samples := PackedFloat32Array()
	samples.resize(count)
	var noise := RandomNumberGenerator.new()
	noise.seed = int(frequency)
	for i in count:
		var t := float(i) / MIX_RATE
		var value := 0.0
		for partial in ratios.size():
			value += levels[partial] * exp(-decays[partial] * t) * sin(TAU * frequency * ratios[partial] * t)
		if t < 0.002:
			value += noise.randf_range(-0.5, 0.5) * (1.0 - t / 0.002)
		samples[i] = value * 0.4
	return samples


## Froissement de papier : un souffle court, adouci.
func _rustle_samples() -> PackedFloat32Array:
	var count := int(MIX_RATE * 0.10)
	var samples := PackedFloat32Array()
	samples.resize(count)
	var noise := RandomNumberGenerator.new()
	noise.seed = 7
	var smoothed := 0.0
	for i in count:
		var t := float(i) / MIX_RATE
		smoothed = lerpf(smoothed, noise.randf_range(-1.0, 1.0), 0.25)
		samples[i] = smoothed * exp(-30.0 * t) * 0.6
	return samples


## « Pouf » d'une fusion : un souffle sourd et une petite note qui monte.
func _pop_samples() -> PackedFloat32Array:
	var count := int(MIX_RATE * 0.16)
	var samples := PackedFloat32Array()
	samples.resize(count)
	var noise := RandomNumberGenerator.new()
	noise.seed = 11
	var smoothed := 0.0
	var phase := 0.0
	for i in count:
		var t := float(i) / MIX_RATE
		smoothed = lerpf(smoothed, noise.randf_range(-1.0, 1.0), 0.08)
		phase += TAU * lerpf(520.0, 900.0, t / 0.16) / MIX_RATE
		var envelope := exp(-22.0 * t)
		samples[i] = (smoothed * 0.9 + sin(phase) * 0.35) * envelope * 0.6
	return samples


func _to_stream(samples: PackedFloat32Array) -> AudioStreamWAV:
	var bytes := PackedByteArray()
	bytes.resize(samples.size() * 2)
	for i in samples.size():
		bytes.encode_s16(i * 2, int(clampf(samples[i], -1.0, 1.0) * 32767.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = MIX_RATE
	stream.stereo = false
	stream.data = bytes
	return stream
