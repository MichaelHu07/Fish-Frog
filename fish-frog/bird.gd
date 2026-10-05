extends RigidBody3D

@export var flap_boost: float = 5.0
@export var forward_acceleration: float = 8.0
@export var braking_deceleration: float = 12.0
@export var mouse_sensitivity: float = 0.005
@export var maximum_pitch: float = deg_to_rad(60)
@export var maximum_roll: float = deg_to_rad(15)
@export var roll_speed: float = 5.0

@onready var visuals: Node3D = $Visuals
@onready var camera_pivot: Node3D = $CameraPivot

var yaw: float = 0.0
var pitch: float = 0.0
var roll: float = 0.0
var previous_direction := Vector3.ZERO
var turn_speed: float = 0.0


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and not event.is_echo():
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		get_viewport().set_input_as_handled()
		return

	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		return

	if event is InputEventMouseMotion:
		yaw -= event.relative.x * mouse_sensitivity
		pitch = clampf(pitch - event.relative.y * mouse_sensitivity, -maximum_pitch, maximum_pitch)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("Flap") and not event.is_echo():
		apply_central_impulse(Vector3.UP * mass * flap_boost)
		get_viewport().set_input_as_handled()


func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	var motion := state.linear_velocity
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and Input.is_action_pressed("boost"):
		var forward := -Basis.from_euler(Vector3(pitch, yaw, 0.0)).z
		motion += forward * forward_acceleration * state.step
	else:
		# Brake horizontal motion; gravity and flaps still control vertical motion.
		var horizontal := Vector3(motion.x, 0.0, motion.z)
		horizontal = horizontal.move_toward(Vector3.ZERO, braking_deceleration * state.step)
		motion.x = horizontal.x
		motion.z = horizontal.z
	state.linear_velocity = motion

	# Measure actual horizontal travel, independent of mouse or visual heading.
	var travel := Vector3(motion.x, 0.0, motion.z)
	turn_speed = 0.0
	if travel.length() > 0.1:
		var direction := travel.normalized()
		if previous_direction != Vector3.ZERO:
			turn_speed = previous_direction.signed_angle_to(direction, Vector3.UP) / state.step
		previous_direction = direction
	else:
		previous_direction = Vector3.ZERO


func _process(delta: float) -> void:
	var target_roll := clampf(turn_speed / 2.0, -1.0, 1.0) * maximum_roll
	roll = lerp_angle(roll, target_roll, 1.0 - exp(-roll_speed * delta))
	visuals.rotation = Vector3(pitch, yaw, roll)
	camera_pivot.rotation = Vector3(pitch, yaw, 0.0)
