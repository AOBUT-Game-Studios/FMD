extends KinematicBody

#Last Change : 01/04/22

#CHANGELOG
	#Added Grapple

#TODO
#Basic WASD Movement COMPLETE 12/31/21
	#Movement along the horizontal plane COMPLETE 12/11/21
	#Should rotate movement axis is accordance with the camera angle COMPLETE 12/11/21
	#Gradual accelaretion and momentum should be slightly maintained, but not to the point where it feels like sliding COMPLETE 12/31/21
	#Increase momentum while in air, so that player has less control over arial movement COMPLETE 12/31/21
#Camera Controls COMPLETE 12/11/21
	#Rotate character and camera according to mouse movement COMPLETE 12/11/21
	#Cap off vertical rotation, to prevent the camera from going upside down COMPLETE 12/11/21
#Jumping and airtime physics
	#Jump should be a low to the ground boost of momentum (B Hopping) COMPLETE 12/31/21 
	#Midair jumps allow for realignment of trajectory 
	#The player should feel in control while midair, but should still have limited horizontal influence outside of jumping and grappling
#Grapple Mechanic
	#Pulls player towards viable object, and past the object COMPLETE 01/04/22
	#Player receives an extra jump after a successful grapple, which allows them to realign trajectory
	#Grapping disables players collision with a majority of in game set peices, excluding walls and platforms
	#The grapple should launch the player in the direction of the grappled object, and past that object COMPLETE 01/04/22
	#The trajectory of the launch is not direct, but rather an arc. COMPLETE 01/04/22
	#Grapples should feel good to chain, with a moderate cooldown.
	#You cannot grapple mid launch.
#Swatting
	#A weighted attack that lauches an enemy in the direction it was hit
#Shotgun
	#A blast attack, that instanly kills an enemy if hit in their weak spot
	#Shotgun blasts have recoil, which can be used to readjust midair
	#Shotgun has a reload animation after every shot
	
#REFERENCE
	#First person camera and movement : http://kidscancode.org/godot_recipes/basics/3d/101_3d_07/
	
#TO RESEARCH
	#global_transform.basis
	#Camera rotation system
	#How to maintain velocity between frames

onready var cam = $Pivot/Camera #Camera Node
onready var pivot = $Pivot #Camera Pivot Node

export (float) var gravity = -9 #Force of gravity, applied to the -y axis, multiplied by delta
export (float) var max_speed = 14 #Horizontal Speed Cap
export (float) var mouse_sens = 0.02 #Camera movement sensitivity
export (float) var jump_strength = 55 #Initial jump strength, compared to gravity
export (float) var jump_drag = 20 #How difficult it is to change direction mid air
export (float) var jump_accel_init = 3 #Starting acceleration value when jumping
export (float) var jump_accel_cap = -20 #cut off point for increasing jump gravity
export (float) var run_drag = 5 #How hard it is to turn when running
export (float) var grapple_drag = 200
export (float) var grapple_time_init = 1

onready var jump_accel = jump_accel_init 
var velocity = Vector3() #The players velocity, currently maintains the y axis info between frames
var jumping = false #Whether or not the player is able to jump
var grapple = false
onready var grapple_time = grapple_time_init
var jump_current = 0 #Current Jump Strength Value
var was_on_floor #True if player was on floor the previous frame
var snap = Vector3.DOWN #Toggle snap to ground, empty vector is off, while downward is on
var grapple_target = null

func _ready():
	#Capture the mouse upon launching scene
	#TODO Move to another script later
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

#Get the player input, and return the direction of input in accordance to the camera rotation
#Movement along the horizontal axis atm
func get_input():
	var input_dir = Vector3() #Stores the input direction in accordance to the camera rotation
	#Check input, and then add the proper direction to input_dir
	if Input.is_action_pressed("forward"):
		input_dir += -cam.global_transform.basis.z
	if Input.is_action_pressed("backward"):
		input_dir += cam.global_transform.basis.z
	if Input.is_action_pressed("left"):
		input_dir += -cam.global_transform.basis.x
	if Input.is_action_pressed("right"):
		input_dir += cam.global_transform.basis.x
	if Input.is_action_just_pressed("jump") and !jumping:
		jumping = true
		jump_current = jump_strength
		snap = Vector3()
	if Input.is_action_just_pressed("grapple") and !grapple and grapple_target != null:
		grapple(grapple_target)
		snap = Vector3()
	#Uncapture mouse
	if Input.is_action_just_pressed("menu"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	#Returns a vector 3 containing the normalized horizontal movement information
	return input_dir.normalized()

#Jump arc calculations
func jump(delta):
	#Check if that player left the floor since the last frame, and prevent them from jumping, while still applying velocity
	if !is_on_floor() and was_on_floor and !jumping:
		was_on_floor = false
		jumping = true
		jump_current = gravity * -1
	#Check if player is on floor
	elif is_on_floor():
		was_on_floor = true
	
	#Check if player reconnects with floor
	if is_on_floor() and jump_current < jump_strength - 10:
		jumping = false
		snap = Vector3.DOWN
		jump_accel = jump_accel_init
	
	#Return jump value depending on jumping state
	if jumping:
		if jump_current > jump_accel_cap:
			jump_accel += delta
			jump_current -= jump_accel
		return jump_current * delta
	else:
		return 0

#Get the mouse movement input to control the camera
func _unhandled_input(event):
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		pivot.rotate_x(-event.relative.y * mouse_sens)
		rotate_y(-event.relative.x * mouse_sens)
		pivot.rotation.x = clamp(pivot.rotation.x, -1.2, 1.2)

#Grapple velocity calculations
func grapple(target):
	grapple = true
	var dir = (target.get_transform().origin - get_transform().origin).normalized()
	var distance = (target.get_transform().origin - get_transform().origin).length()
	velocity = dir * max_speed * (distance / 5)
	grapple_time = grapple_time_init

#Runs the physics inputs every frame
func _physics_process(delta):
	if !grapple:
		velocity.y += (gravity * delta) + jump(delta) #Adds new gravity to this frame
	var desired_velocity = get_input() * max_speed
	
	if grapple:
		grapple_time -= delta
		if grapple_time <= 0:
			grapple = false
			snap = Vector3.DOWN
	
	#Maintain a large portion of previous frames horizontal plane velocity, increasing drag increases effort needed to change direction
	if grapple:
		velocity.x = ((velocity.x / grapple_drag) * (grapple_drag - 1)) + (desired_velocity.x / grapple_drag) * 2
		velocity.z = ((velocity.z / grapple_drag) * (grapple_drag - 1)) + (desired_velocity.z / grapple_drag) * 2
		velocity.y = velocity.y
	elif !jumping:
		velocity.x = ((velocity.x / run_drag) * (run_drag - 1)) + (desired_velocity.x / run_drag)
		velocity.z = ((velocity.z / run_drag) * (run_drag - 1)) + (desired_velocity.z / run_drag)
	elif jumping:
		velocity.x = ((velocity.x / jump_drag) * (jump_drag - 1)) + (desired_velocity.x / jump_drag) * 1.5
		velocity.z = ((velocity.z / jump_drag) * (jump_drag - 1)) + (desired_velocity.z / jump_drag) * 1.5
		
	velocity = move_and_slide_with_snap(velocity ,snap, Vector3.UP, false, 4, 0.75, true) #Finally move the player
	

func grapple_detect_enter(body):
	if body.is_in_group('grapple'):
		grapple_target = body


func grapple_detect_exit(body):
	if body.is_in_group('grapple') and grapple_target == body:
		grapple_target = null
