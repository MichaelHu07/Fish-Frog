extends SceneTree

func _initialize():
	call_deferred("run_checks")

var failures: int = 0

func check(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		failures += 1
		return
	print("PASS: ", message)

func run_checks():
	var controller = load("res://bird.gd")
	if controller == null or not controller.can_instantiate():
		push_error("Bird controller must compile before flight can work")
		quit(1)
		return
	check(InputMap.has_action("boost"), "Shift throttle action exists")
	var bound_to_shift = false
	for event in InputMap.action_get_events("boost"):
		if event is InputEventKey and event.physical_keycode == KEY_SHIFT:
			bound_to_shift = true
	check(bound_to_shift, "Throttle is bound to Shift")
	var world = load("res://world.tscn").instantiate()
	root.add_child(world)
	var bird = world.get_node("bird")
	# Prevent physical mouse movement from interfering with scripted input.
	bird.set_process_unhandled_input(false)
	check(bird is RigidBody3D, "Bird is a rigid body")
	check(bird.lock_rotation, "Physics body stays upright")
	check(world.get_node("character").process_mode == Node.PROCESS_MODE_DISABLED, "Only bird receives gameplay input")
	check(root.get_camera_3d() == bird.get_node("CameraPivot/SpringArm3D/Camera3D"), "Bird camera is active")
	# Isolate controller behavior from obstacles and gravity for the throttle check.
	bird.global_position = Vector3(0, 30, 0)
	bird.gravity_scale = 0.0
	bird.linear_damp_mode = RigidBody3D.DAMP_MODE_REPLACE
	bird.linear_damp = 0.0
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	Input.action_press("boost")
	await create_timer(0.3, true, true).timeout
	check(bird.linear_velocity.z < -1.0, "Holding Shift accelerates forward")
	Input.action_release("boost")
	await create_timer(0.7, true, true).timeout
	check(Vector2(bird.linear_velocity.x, bird.linear_velocity.z).length() < 0.01, "Releasing Shift stops horizontal movement")
	var vy = bird.linear_velocity.y
	var flap = InputEventKey.new()
	flap.physical_keycode = KEY_SPACE
	flap.pressed = true
	bird._unhandled_input(flap)
	await create_timer(0.08, true, true).timeout
	check(bird.linear_velocity.y > vy + 4.0, "Space adds upward momentum")
	flap.pressed = false
	bird._unhandled_input(flap)
	var mouse = InputEventMouseMotion.new()
	mouse.relative = Vector2(20, -10)
	bird._unhandled_input(mouse)
	await create_timer(0.08, true, false).timeout
	check(bird.yaw < -0.05 and bird.pitch > 0.02, "Mouse steers yaw and pitch")
	check(absf(bird.get_node("Visuals").rotation.z) < 0.00001, "Mouse movement alone does not bank a stationary bird")
	check(absf(bird.get_node("CameraPivot").rotation.z) < 0.00001, "Camera never banks")
	check(bird.rotation.is_equal_approx(Vector3.ZERO), "Bird collider remains upright")
	var before_turn_thrust = bird.linear_velocity
	Input.action_press("boost")
	await create_timer(0.3, true, true).timeout
	check(bird.linear_velocity.x > 0.1, "Mouse yaw changes the propulsion direction")
	check(bird.linear_velocity.y > before_turn_thrust.y + 0.05, "Mouse pitch changes vertical propulsion")
	mouse.relative = Vector2(40, 0)
	bird._unhandled_input(mouse)
	await create_timer(0.3, true, true).timeout
	check(bird.get_node("Visuals").rotation.z < -0.001, "Bird banks while its travel direction curves right")
	check(absf(bird.get_node("CameraPivot").rotation.z) < 0.00001, "Camera stays upright during a flight turn")
	Input.action_release("boost")
	var key = InputEventKey.new()
	key.keycode = KEY_ESCAPE
	key.pressed = true
	bird._unhandled_input(key)
	await create_timer(0.05, true, false).timeout
	check(Input.mouse_mode == Input.MOUSE_MODE_VISIBLE, "Escape releases the mouse once")
	var old_yaw = bird.yaw
	bird._unhandled_input(mouse)
	await create_timer(0.05, true, false).timeout
	check(is_equal_approx(bird.yaw, old_yaw), "Released mouse does not steer")
	bird.gravity_scale = 1.0
	await create_timer(0.4, true, true).timeout
	check(bird.linear_velocity.y < vy + 3.0, "Gravity still acts while throttle is released")
	await create_timer(1.0, true, true).timeout
	check(absf(bird.get_node("Visuals").rotation.z) < 0.01, "Bank returns upright after turning stops")
	bird.global_position = Vector3(0, 4, 0)
	bird.linear_velocity = Vector3.ZERO
	await create_timer(1.2, true, true).timeout
	check(bird.global_position.y > 1.8 and bird.global_position.y < 2.2, "Bird collides with the floor instead of falling through")
	if failures == 0:
		print("ALL FLIGHT CHECKS PASSED")
	quit(0 if failures == 0 else 1)






