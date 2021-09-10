extends KinematicBody2D

#move variable
const FLOOR_NORMAL = Vector2.UP
export var speed: = Vector2(120, 200)
var velocity: = Vector2(0,0)
export var gravity: = 700.0
var is_facing_right = true
#anim variable
var state_machine
#data variable
var hp:= 100
const SAVE_DIR = "user://saves/"
var save_path = SAVE_DIR + "ủplayer.dat"
var data = {
	"hp": 100
}
#anchor variable
var anchor = preload("res://environments/Anchor.tscn")
var anchor_was_set = false

func _ready() -> void:
	save_hp(90)
	hp = load_hp()
	state_machine = $AnimationTree.get("parameters/playback")
	pass # Replace with function body.

func _physics_process(delta: float) -> void:
	#move script
	var is_jump_interrupted: = Input.is_action_just_released("jump") and velocity.y < 0.0
	var direction: = get_direction()
	velocity = calculate_move_velocity(velocity, direction, speed, is_jump_interrupted)
	velocity = move_and_slide(velocity, FLOOR_NORMAL)
	
	flip_check()
	
	anim_update()
	#anim attack
	if Input.is_action_just_pressed("attack") and $AttackCoolDown.time_left <= 0:
		attack()
	#anchor interact
	if Input.is_action_just_pressed("anchor"):
		anchor_interact()
	#test button pressed
	if Input.is_action_just_pressed("test"):
		print(hp)

func get_direction() -> Vector2:
	return Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		-1.0 if Input.is_action_just_pressed("jump") and is_on_floor() else 0.0
	)
	
func calculate_move_velocity(
	linear_veclocity: Vector2,
	direction: Vector2,
	speed: Vector2,
	is_jump_interrupted: bool
	) -> Vector2:
	var out = linear_veclocity
	out.x = speed.x * direction.x
	out.y += gravity * get_physics_process_delta_time()
	if direction.y == -1:
		out.y = speed.y * direction.y
	if is_jump_interrupted:
		out.y = 0
	return out

func flip_check():
	if velocity.x > 0 and is_facing_right == false:
		$Sprite.scale.x = 1
		is_facing_right = true
	if velocity.x < 0 and is_facing_right == true:
		$Sprite.scale.x = -1
		is_facing_right = false

func anim_update():
	if velocity.length() == 0:
		state_machine.travel("Idle")
	if velocity.length() != 0:
		state_machine.travel("Move")
	if not is_on_floor():
		state_machine.travel("Jump")

func anchor_interact():
	#print("hello")
	if anchor_was_set == false:
		var out = anchor.instance()
		out.position = self.global_position
		get_parent().add_child_below_node(get_tree().get_root().get_node("Scene").get_node("World").get_node("Environment"), out)
		anchor_was_set = true
	else:
		#print(get_tree().get_root().get_node("Scene").get_node("World").get_node("Anchor"))
		var anchor_pos = get_tree().get_root().get_node("Scene").get_node("World").get_node("Anchor").global_position
		self.position = anchor_pos
		get_tree().get_root().get_node("Scene").get_node("World").get_node("Anchor").queue_free()
		anchor_was_set = false

func attack():
	$AttackCoolDown.start()
	var attack_effect
	if is_facing_right:
		attack_effect = load("res://effects/AttackRight.tscn")
	else:
		attack_effect = load("res://effects/AttackLeft.tscn")
	var out = attack_effect.instance()
	out.position = $Sprite/Hand.global_position
	get_parent().add_child_below_node(get_tree().get_root().get_node("Scene").get_node("World").get_node("Environment"), out)

func load_hp():
	var player_data
	var file = File.new()
	if file.file_exists(save_path):
		var err = file.open(save_path, File.READ)
		if err == OK:
			player_data = file.get_var()
			file.close()
			return player_data["hp"]
	return

func save_hp(value):
	var new_data = {
		"hp": value
	}
	
	var dir = Directory.new()
	if !dir.dir_exists(SAVE_DIR):
		dir.make_dir_recursive(SAVE_DIR)
	
	var file = File.new()
	var err = file.open(save_path, File.WRITE)
	if err == OK:
		file.store_var(new_data)
		file.close()
