extends Node3D

# Original 3D models, composed from primitives. Arcade screenshots guide palette/layout.
const SAVE_PATH := "user://penguin_wars.cfg"
const PINK := Color("fc69bb")
const BLUE := Color("258fe7")
const CREAM := Color("fff4d9")
const BALL_RADIUS := 0.3
const BALL_STEP := 1.0 / 120.0
var rng := RandomNumberGenerator.new()
var balls: Array[Dictionary] = []
var player: Node3D
var rival: Node3D
var camera: Camera3D
var hud: Label
var hint: Label
var overlay: PanelContainer
var heading: Label
var detail: Label
var play_button: Button
var pause_button: Button
var ball_button: Button
var held_ball: Dictionary = {}
var time_left := 60.0
var cooldown := 0.0
var cpu_cooldown := 0.0
var player_stun := 0.0
var cpu_stun := 0.0
var active := false
var paused := false
var high_score := 0
var score := 0
var round_index := 1
var won := false
var move_left := false
var move_right := false
var pointer_target := 0.0
var clock := 0.0

func _ready() -> void:
	rng.seed = 1985
	var saved := ConfigFile.new()
	if saved.load(SAVE_PATH) == OK:
		high_score = int(saved.get_value("scores", "high", 0))
	_build_world()
	_build_ui()
	_reset_balls()
	_refresh_hud()

func _material(color: Color, roughness: float = 0.7) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color.srgb_to_linear()
	mat.roughness = roughness
	return mat

func _shape(parent: Node3D, mesh: Mesh, pos: Vector3, color: Color, size: Vector3 = Vector3.ONE) -> MeshInstance3D:
	var item := MeshInstance3D.new()
	item.mesh = mesh
	item.material_override = _material(color)
	item.position = pos
	item.scale = size
	parent.add_child(item)
	return item

func _box(parent: Node3D, pos: Vector3, size: Vector3, color: Color) -> MeshInstance3D:
	return _shape(parent, BoxMesh.new(), pos, color, size)

func _sphere(parent: Node3D, pos: Vector3, size: Vector3, color: Color) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radial_segments = 16
	mesh.rings = 8
	return _shape(parent, mesh, pos, color, size)

func _animal(pos: Vector3, tint: Color, bear: bool = false) -> Node3D:
	var root := Node3D.new()
	add_child(root)
	root.position = pos
	_sphere(root, Vector3(0, 0.7, 0), Vector3(1.15, 0.8, 0.95), tint)
	_sphere(root, Vector3(0, 0.64, 0.37), Vector3(0.8, 0.58, 0.24), CREAM)
	_sphere(root, Vector3(0, 1.35, 0.04), Vector3(1.05, 0.53, 0.9), tint)
	for side in [-1.0, 1.0]:
		_sphere(root, Vector3(side * 0.22, 1.43, 0.43), Vector3(0.25, 0.17, 0.15), Color.WHITE)
		_sphere(root, Vector3(side * 0.22, 1.43, 0.51), Vector3(0.1, 0.1, 0.07), Color("192638"))
		_sphere(root, Vector3(side * 0.36, 0.12, 0.2), Vector3(0.42, 0.12, 0.55), Color("fbb54e"))
		var wing := _sphere(root, Vector3(side * 0.61, 0.8, 0), Vector3(0.28, 0.5, 0.4), tint)
		wing.rotation.z = side * 0.35
		if bear:
			_sphere(root, Vector3(side * 0.45, 1.77, 0), Vector3(0.35, 0.2, 0.3), tint)
	_sphere(root, Vector3(0, 1.2, 0.53), Vector3(0.38, 0.12, 0.35), Color("ffb637") if not bear else Color("513b4c"))
	return root

func _build_world() -> void:
	var environment := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("8b8fcd")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("d3daff")
	env.ambient_light_energy = 0.3
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.environment = env
	add_child(environment)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-55, -25, 0)
	light.light_energy = 0.85
	light.shadow_enabled = true
	add_child(light)
	camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 23.0
	camera.position = Vector3(0, 14, 20)
	add_child(camera)
	camera.look_at(Vector3(0, 0, -0.4))
	camera.current = true
	_box(self, Vector3(0, -1.4, 0), Vector3(27, 0.7, 25), Color("655f8a"))
	_box(self, Vector3(0, -0.65, 0), Vector3(11.2, 0.8, 14), Color("725058"))
	_box(self, Vector3(0, -0.12, 0), Vector3(10.3, 0.25, 12.6), Color("224f49"))
	_box(self, Vector3(0, 0, 0), Vector3(9.8, 0.13, 12.2), Color("3ea667"))
	for x in [-5.0, 5.0]:
		_box(self, Vector3(x, 0.13, 0), Vector3(0.18, 0.25, 12.5), Color("f3c777"))
	for z in [-6.2, 6.2]:
		_box(self, Vector3(0, 0.13, z), Vector3(10.2, 0.25, 0.18), Color("f3c777"))
	_box(self, Vector3(0, 0.09, 0), Vector3(9.8, 0.03, 0.1), CREAM)
	_box(self, Vector3(0, 0.09, 0), Vector3(0.07, 0.03, 12.2), Color("8fd69b"))
	for z in [-5.0, 5.0]:
		_box(self, Vector3(0, 0.09, z), Vector3(9.8, 0.03, 0.08), CREAM)
	# Timber bleachers and a crowd of toy-like animal spectators.
	for side in [-1.0, 1.0]:
		for row in range(2):
			_box(self, Vector3(side * (7.0 + row * 1.8), -0.25 + row * 0.55, 0), Vector3(1.5, 0.5, 13), Color("725e83"))
			for seat in range(8):
				var spectator := _animal(Vector3(side * (7.0 + row * 1.8), 0.05 + row * 0.55, -5.8 + seat * 1.65), Color.from_hsv(float(seat + row * 3) / 12.0, 0.35, 0.95), seat % 3 == 0)
				spectator.scale = Vector3.ONE * 0.65
				spectator.rotation.y = -side * PI / 2.0
	for i in range(9):
		var mountain := CylinderMesh.new()
		mountain.top_radius = 0.0
		mountain.bottom_radius = 2.8
		mountain.height = 4.5
		_shape(self, mountain, Vector3(-13 + i * 3.2, 0.1, -11.8), Color("6c799e"))
		var snow := CylinderMesh.new()
		snow.top_radius = 0.0
		snow.bottom_radius = 0.9
		snow.height = 1.4
		_shape(self, snow, Vector3(-13 + i * 3.2, 1.68, -11.8), Color("d6dff0"))
	player = _animal(Vector3(0, 0.18, 5.2), BLUE)
	player.rotation.y = PI
	rival = _animal(Vector3(0, 0.18, -5.2), Color("b88872"), true)

func _label(text: String, size: int, color: Color = CREAM) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return label

func _button(text: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = text
	# Space always reaches the game, even after a mouse/touch button press.
	button.focus_mode = Control.FOCUS_NONE
	button.custom_minimum_size = Vector2(95, 52)
	button.add_theme_font_size_override("font_size", 17)
	button.pressed.connect(action)
	return button

func _build_ui() -> void:
	var canvas := CanvasLayer.new()
	add_child(canvas)
	var top := PanelContainer.new()
	top.position = Vector2(12, 14)
	top.size = Vector2(456, 90)
	canvas.add_child(top)
	var stack := VBoxContainer.new()
	top.add_child(stack)
	stack.add_child(_label("PENGUIN-KUN WARS", 20, Color("ffcf6e")))
	hud = _label("", 17)
	stack.add_child(hud)
	hint = _label("Clear your side • fewer balls wins", 13)
	stack.add_child(hint)
	var controls := HBoxContainer.new()
	controls.position = Vector2(12, 726)
	controls.size = Vector2(456, 58)
	controls.add_theme_constant_override("separation", 8)
	canvas.add_child(controls)
	var left := _button("◀", func(): pass)
	left.button_down.connect(func(): move_left = true)
	left.button_up.connect(func(): move_left = false)
	controls.add_child(left)
	var right := _button("▶", func(): pass)
	right.button_down.connect(func(): move_right = true)
	right.button_up.connect(func(): move_right = false)
	controls.add_child(right)
	ball_button = _button("PICK UP", _player_ball_action)
	ball_button.custom_minimum_size.x = 140
	controls.add_child(ball_button)
	pause_button = _button("Ⅱ", _toggle_pause)
	controls.add_child(pause_button)
	overlay = PanelContainer.new()
	overlay.position = Vector2(28, 200)
	overlay.size = Vector2(424, 320)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.07, 0.12, 0.21, 0.94)
	style.corner_radius_top_left = 20
	style.corner_radius_top_right = 20
	style.corner_radius_bottom_left = 20
	style.corner_radius_bottom_right = 20
	style.content_margin_left = 24
	style.content_margin_right = 24
	style.content_margin_top = 25
	style.content_margin_bottom = 25
	overlay.add_theme_stylebox_override("panel", style)
	canvas.add_child(overlay)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 18)
	overlay.add_child(content)
	content.add_child(_label("ARCADE • 3D EDITION", 15, Color("fc8fba")))
	heading = _label("PENGUIN-KUN\nWARS", 32, Color("ffcf6e"))
	content.add_child(heading)
	detail = _label("Clear the pink balls from your side.\nSpace: pick up, then press again to throw.\nMove with ◀ ▶ or drag while holding.", 15)
	content.add_child(detail)
	play_button = _button("PLAY", _start_round)
	content.add_child(play_button)

func _reset_balls() -> void:
	held_ball = {}
	for ball in balls:
		ball.node.queue_free()
	balls.clear()
	for side in [-1, 1]:
		for lane in range(5):
			var node := _sphere(self, Vector3(-3.2 + lane * 1.6, 0.38, side * 4.0), Vector3.ONE * 0.6, PINK)
			balls.append({"node": node, "velocity": Vector3.ZERO, "side": side, "held": false})

func _start_round() -> void:
	if paused:
		_toggle_pause()
		return
	if won:
		round_index += 1
	else:
		round_index = 1
		score = 0
	won = false
	time_left = 60.0
	cooldown = 0.0
	cpu_cooldown = 1.4
	player_stun = 0.0
	cpu_stun = 0.0
	player.position.x = 0.0
	pointer_target = 0.0
	rival.position.x = 0.0
	_reset_balls()
	active = true
	overlay.hide()
	_refresh_hud()

func _throw(side: int) -> void:
	var character := player if side == 1 else rival
	var nearest := _nearest_resting_ball(side, character.position.x)
	if nearest.is_empty():
		return
	nearest.node.position.x = character.position.x
	nearest.velocity = Vector3(0, 0, -side * (8.0 + minf(round_index * 0.3, 2.0)))

func _nearest_resting_ball(side: int, x: float) -> Dictionary:
	var nearest: Dictionary = {}
	var distance := 100.0
	for ball in balls:
		if ball.side == side and ball.velocity == Vector3.ZERO and not ball.held:
			var d: float = absf(ball.node.position.x - x)
			if d < distance:
				distance = d
				nearest = ball
	if nearest.is_empty() or distance > 1.6:
		return {}
	return nearest

func _player_ball_action() -> void:
	if not active or paused or cooldown > 0.0 or player_stun > 0.0:
		return
	if held_ball.is_empty():
		var nearest := _nearest_resting_ball(1, player.position.x)
		if nearest.is_empty():
			return
		held_ball = nearest
		held_ball.held = true
		_update_held_ball()
	else:
		held_ball.held = false
		held_ball.node.position = Vector3(player.position.x, 0.38, 4.0)
		held_ball.velocity = Vector3(0, 0, -(8.0 + minf(round_index * 0.3, 2.0)))
		held_ball = {}
		cooldown = 0.35
	_refresh_hud()

func _update_held_ball() -> void:
	if not held_ball.is_empty():
		# Lift it above the head so the near-side penguin cannot hide it from the camera.
		held_ball.node.position = player.position + Vector3(0, 2.15, -0.25)

func _process(delta: float) -> void:
	clock += delta
	if not active or paused:
		return
	time_left = maxf(0, time_left - delta)
	cooldown -= delta
	cpu_cooldown -= delta
	player_stun = maxf(0, player_stun - delta)
	cpu_stun = maxf(0, cpu_stun - delta)
	var axis := float(move_right) - float(move_left)
	if Input.is_physical_key_pressed(KEY_LEFT) or Input.is_physical_key_pressed(KEY_A):
		axis -= 1
	if Input.is_physical_key_pressed(KEY_RIGHT) or Input.is_physical_key_pressed(KEY_D):
		axis += 1
	if axis != 0:
		pointer_target = clampf(pointer_target + axis * delta * 6.0, -4.1, 4.1)
	if player_stun <= 0:
		player.position.x = move_toward(player.position.x, pointer_target, 8.0 * delta)
	_update_held_ball()
	player.rotation.z = sin(clock * 25) * 0.28 if player_stun > 0 else 0.0
	rival.rotation.z = sin(clock * 25) * 0.28 if cpu_stun > 0 else 0.0
	# The CPU moves toward a ball before rolling it, with a deliberate reaction delay.
	var target_x := rival.position.x
	var best := 100.0
	for ball in balls:
		if ball.side == -1 and ball.velocity == Vector3.ZERO and not ball.held:
			var distance: float = absf(ball.node.position.x - rival.position.x)
			if distance < best:
				best = distance
				target_x = ball.node.position.x
	if cpu_stun <= 0:
		rival.position.x = move_toward(rival.position.x, target_x, (2.4 + round_index * 0.2) * delta)
		if cpu_cooldown <= 0:
			_throw(-1)
			cpu_cooldown = rng.randf_range(0.7, 1.3)
	_advance_balls(delta)
	_refresh_hud()
	var count := _player_count()
	var moving := false
	for ball in balls:
		if ball.velocity != Vector3.ZERO:
			moving = true
	if time_left <= 0 or (not moving and (count == 0 or count == 10)):
		_finish_round(count)

func _advance_balls(delta: float) -> void:
	# Small steps keep opposing balls from crossing through one another at low FPS.
	var remaining := delta
	while remaining > 0.0:
		var step := minf(remaining, BALL_STEP)
		remaining -= step
		for ball in balls:
			if ball.held or ball.velocity == Vector3.ZERO:
				continue
			ball.node.position += ball.velocity * step
			ball.node.rotate_x(step * ball.velocity.z)
		_resolve_ball_collisions()
		for ball in balls:
			if ball.held or ball.velocity == Vector3.ZERO:
				continue
			ball.side = 1 if ball.node.position.z >= 0 else -1
			if absf(ball.node.position.z) < 4.3:
				continue
			var recipient := player if ball.side == 1 else rival
			if absf(ball.node.position.x - recipient.position.x) < 0.8:
				if ball.side == 1:
					player_stun = 0.8
				else:
					cpu_stun = 0.8
			ball.node.position.z = ball.side * 4.0
			ball.velocity = Vector3.ZERO
			# Spread arrivals so every ball remains reachable.
			ball.node.position.x = clampf(ball.node.position.x + rng.randf_range(-0.45, 0.45), -4.0, 4.0)

func _resolve_ball_collisions() -> void:
	var diameter := BALL_RADIUS * 2.0
	for i in range(balls.size()):
		var a := balls[i]
		if a.held or a.velocity == Vector3.ZERO:
			continue
		for j in range(i + 1, balls.size()):
			var b := balls[j]
			if b.held or a.velocity.z * b.velocity.z >= 0.0:
				continue
			var separation: Vector3 = a.node.position - b.node.position
			var relative_velocity: Vector3 = a.velocity - b.velocity
			if separation.length_squared() > diameter * diameter or separation.dot(relative_velocity) >= 0.0:
				continue
			# Keep arcade lane movement: each approaching ball reverses toward its sender.
			var contact_z := sqrt(maxf(0.0, diameter * diameter - separation.x * separation.x)) + 0.001
			var midpoint: float = (a.node.position.z + b.node.position.z) * 0.5
			var direction: float = -signf(a.velocity.z)
			a.node.position.z = midpoint + direction * contact_z * 0.5
			b.node.position.z = midpoint - direction * contact_z * 0.5
			a.velocity = -a.velocity
			b.velocity = -b.velocity

func _player_count() -> int:
	var count := 0
	for ball in balls:
		if ball.side == 1:
			count += 1
	return count

func _refresh_hud() -> void:
	var count := _player_count()
	hud.text = "YOU %d    •    %02d SEC    •    CPU %d" % [count, ceili(time_left), 10 - count]
	hint.text = "ROUND %02d    SCORE %05d    BEST %05d" % [round_index, score, high_score]
	ball_button.text = "PICK UP" if held_ball.is_empty() else "THROW"

func _finish_round(count: int) -> void:
	active = false
	won = count < 5
	if won:
		score += (10 - count) * 100 + int(time_left) * 10
	if score > high_score:
		high_score = score
		var saved := ConfigFile.new()
		saved.set_value("scores", "high", high_score)
		saved.save(SAVE_PATH)
	heading.text = "YOU WIN!" if won else ("DRAW" if count == 5 else "RIVAL WINS")
	detail.text = "Your side: %d balls • Rival: %d\nScore %05d • Best %05d" % [count, 10 - count, score, high_score]
	play_button.text = "NEXT ROUND" if won else "PLAY AGAIN"
	overlay.show()
	_refresh_hud()

func _toggle_pause() -> void:
	if not active:
		return
	paused = not paused
	pause_button.text = "▶" if paused else "Ⅱ"
	if paused:
		heading.text = "PAUSED"
		detail.text = "Take a breather.\nYour match will wait."
		play_button.text = "RESUME"
		overlay.show()
	else:
		overlay.hide()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_SPACE:
			_player_ball_action()
		elif event.keycode == KEY_ESCAPE:
			_toggle_pause()
	if event is InputEventScreenDrag:
		pointer_target = clampf((event.position.x / 480.0 - 0.5) * 10.0, -4.1, 4.1)
	if event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		pointer_target = clampf((event.position.x / 480.0 - 0.5) * 10.0, -4.1, 4.1)

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and active and not paused:
		_toggle_pause()
