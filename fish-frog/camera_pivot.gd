extends Node3D

@onready var spring_arm: SpringArm3D = $SpringArm3D
@onready var camera: Camera3D = $SpringArm3D/Camera3D


func _ready() -> void:
	spring_arm.add_excluded_object((get_parent() as PhysicsBody3D).get_rid())
	camera.make_current()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
