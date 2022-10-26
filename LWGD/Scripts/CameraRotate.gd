extends Spatial

var hoverstatus:float = 0

func _ready():
	pass

func _process(delta):
	self.rotate_y(delta)
	hoverstatus += delta
	self.translation.y = 2 * sin(hoverstatus)
