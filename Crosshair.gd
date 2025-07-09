extends Control

@export var crosshair_size := 16  # Taille totale du crosshair
@export var thickness := 2        # Largeur des traits
@export var color := Color.WHITE

func _draw():
	var h = int(crosshair_size / 2)
	draw_rect(Rect2(Vector2(-h, -thickness/2), Vector2(crosshair_size, thickness)), color) # Horizontal
	draw_rect(Rect2(Vector2(-thickness/2, -h), Vector2(thickness, crosshair_size)), color) # Vertical

func _ready():
	set_process(true)
	queue_redraw()

func _process(_delta):
	queue_redraw()
