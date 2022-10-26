extends Line2D

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

export var un_selected_color: Color
export var selected_color: Color

onready var collision: CollisionPolygon2D = $StaticBody2D/CollisionPolygon2D
var is_select = false

# Called when the node enters the scene tree for the first time.
func _ready():
	set_line([Vector2(0,0), Vector2(100,100)], 2)
	$StaticBody2D.connect("mouse_entered", self, "mouse_entry_exit", [true])
	$StaticBody2D.connect("mouse_exited", self, "mouse_entry_exit", [false])
	default_color = un_selected_color


func mouse_entry_exit(flage):
	print("aaaa")
	is_select = flage
	default_color = selected_color if is_select else un_selected_color

func set_line(screen_points: PoolVector2Array, width):
	var local_pos = []
	for index in screen_points.size():
		local_pos.push_back((screen_points[index]))

	var poly = []
	var line = (screen_points[0] - screen_points[1]).normalized()
	var normal = Vector2(line.y, -line.x)
	var h_width = width / 2 + 1
	poly.append((screen_points[0] + normal * h_width))
	poly.append((screen_points[0] - normal * h_width))
	poly.append((screen_points[1] - normal * h_width))
	poly.append((screen_points[1] + normal * h_width))

	self.points = local_pos
	collision.polygon = poly
	self.width = width



func move_to(screen_point):
	var line: Vector2 = (to_global(points[0]) - to_global(points[1])).normalized()
	var normal = Vector2(line.y, -line.x)
	var local_pos = to_local(screen_point)

	var distance = normal.dot(screen_point) - normal.dot(to_global(points[0]))
	global_position += normal * distance
