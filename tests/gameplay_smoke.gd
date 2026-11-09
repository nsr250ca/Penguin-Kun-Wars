extends SceneTree

# Run: Godot --headless --path . --script res://tests/gameplay_smoke.gd
var game: Node
var failures := 0

func _initialize() -> void:
	_run.call_deferred()

func _check(condition: bool, description: String) -> void:
	if not condition:
		failures += 1
		push_error(description)

func _space(echo: bool = false) -> void:
	var event := InputEventKey.new()
	event.keycode = KEY_SPACE
	event.pressed = true
	event.echo = echo
	game._unhandled_input(event)

func _round() -> void:
	game.paused = false
	game.won = false
	game._start_round()
	game.cpu_cooldown = 1000.0

func _pair(x_offset: float = 0.0, speed_b: float = -10.0) -> Array:
	game._reset_balls()
	var a: Dictionary = game.balls[0]
	var b: Dictionary = game.balls[1]
	a.node.position = Vector3(0, 0.38, -1)
	b.node.position = Vector3(x_offset, 0.38, 1)
	a.velocity = Vector3(0, 0, 10)
	b.velocity = Vector3(0, 0, speed_b)
	return [a, b]

func _run() -> void:
	game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	_round()
	_space()
	_check(not game.held_ball.is_empty(), "First Space must pick up a ball")
	var carried: Dictionary = game.held_ball
	_check(carried.held and carried.velocity == Vector3.ZERO, "Pickup must not launch the ball")
	_check(game.ball_button.text == "THROW", "Mobile control must change to THROW")
	_space(true)
	_check(not game.held_ball.is_empty(), "Key repeat must not throw a carried ball")
	game.pointer_target = 2.4
	game._process(0.4)
	_check(is_equal_approx(carried.node.position.x, game.player.position.x), "Carried ball must follow movement")
	_check(carried.node.position.y > game.player.position.y + 2.0, "Carried ball must be visible above the penguin")
	_check(game._player_count() == 5 and game.balls.size() == 10, "Pickup must preserve inventory and side count")
	game._toggle_pause()
	_space()
	var frozen: Vector3 = carried.node.position
	game._process(0.2)
	_check(carried.held and carried.node.position == frozen, "Pause must block actions and freeze the held ball")
	game._toggle_pause()
	game.player_stun = 0.5
	_space()
	_check(carried.held, "A stunned player must keep holding rather than throw")
	game.player_stun = 0.0
	_space()
	_check(game.held_ball.is_empty() and not carried.held, "Second Space must release the held ball")
	_check(carried.velocity.z < 0 and is_equal_approx(carried.node.position.x, 2.4), "Throw must launch from the moved position")
	_check(game.ball_button.text == "PICK UP", "Mobile control must return to PICK UP")
	_check(game.ball_button.focus_mode == Control.FOCUS_NONE, "A clicked button must not consume Space")
	_round()
	game.ball_button.pressed.emit()
	_check(not game.held_ball.is_empty(), "Touch action must pick up")
	game.ball_button.pressed.emit()
	_check(game.held_ball.is_empty(), "Touch action must throw on the next press")
	_round()
	game.player.position.x = 20
	_space()
	_check(game.held_ball.is_empty(), "Pickup with no nearby ball must do nothing")
	game.player.position.x = 0
	_space()
	_round()
	_check(game.held_ball.is_empty() and game._player_count() == 5, "New rounds must clear carried state")
	var pair := _pair()
	game._advance_balls(0.12)
	_check(pair[0].velocity.z < 0 and pair[1].velocity.z > 0, "Head-on balls must both reverse")
	game._advance_balls(0.05)
	_check(pair[0].velocity.z < 0 and pair[1].velocity.z > 0, "Separating balls must not repeatedly bounce")
	_check(game.balls.size() == 10, "Collision must preserve all ten balls")
	pair = _pair(0.7)
	game._advance_balls(0.2)
	_check(pair[0].velocity.z > 0 and pair[1].velocity.z < 0, "Different lanes must pass without a collision")
	pair = _pair(0.3, -8.0)
	game._advance_balls(0.2)
	_check(is_equal_approx(pair[0].velocity.z, -10.0) and is_equal_approx(pair[1].velocity.z, 8.0), "Offset collision must reverse each ball at its original speed")
	pair = _pair()
	game._advance_balls(0.4)
	_check(pair[0].velocity.z < 0 and pair[1].velocity.z > 0, "A long frame must not allow balls to tunnel through")
	var coarse_z: float = pair[0].node.position.z
	pair = _pair()
	for frame in range(48):
		game._advance_balls(1.0 / 120.0)
	_check(absf(pair[0].node.position.z - coarse_z) < 0.01, "Collision outcome must be stable across frame sizes")
	pair = _pair(0.0, 10.0)
	game._advance_balls(0.1)
	_check(pair[0].velocity.z > 0 and pair[1].velocity.z > 0, "Same-direction balls must not reverse")
	pair = _pair()
	pair[0].held = true
	var held_position: Vector3 = pair[0].node.position
	game._advance_balls(0.3)
	_check(pair[0].node.position == held_position and pair[1].velocity.z < 0, "A held ball must stay out of rolling-ball collisions")
	print("Gameplay checks: ", "PASS" if failures == 0 else "FAIL (%d)" % failures)
	quit(0 if failures == 0 else 1)
