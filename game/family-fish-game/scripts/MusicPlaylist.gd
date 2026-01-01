extends AudioStreamPlayer

@export var tracks: Array[AudioStream] = []
@export var shuffle: bool = false

var _index: int = 0
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()

func _ready() -> void:
	_rng.randomize()
	finished.connect(_on_finished)
	if tracks.is_empty():
		return
	if shuffle:
		_index = _rng.randi_range(0, tracks.size() - 1)
	stream = tracks[_index]
	play()

func _on_finished() -> void:
	if tracks.is_empty():
		return
	if shuffle:
		_index = _rng.randi_range(0, tracks.size() - 1)
	else:
		_index = (_index + 1) % tracks.size()
	stream = tracks[_index]
	play()
