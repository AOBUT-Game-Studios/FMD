extends KinematicBody

#Last Change : 12/11/21

#CHANGELOG
	#Added TODO list
	#Added Reference List
	#Added To research list
	#Added Basic WASD Movement
	#Added camera movement
	#Added Gravity

#TODO
#Basic WASD Movement
	#Movement along the horizontal plane COMPLETE 12/11/21
	#Should rotate movement axis is accordance with the camera angle COMPLETE 12/11/21
	#Gradual accelaretion and momentum should be slightly maintained, but not to the point where it feels like sliding
	#Increase momentum while in air, so that player has less control over arial movement
#Camera Controls
	#Rotate character and camera according to mouse movement COMPLETE 12/11/21
	#Cap off vertical rotation, to prevent the camera from going upside down COMPLETE 12/11/21
#Jumping and airtime physics
	#Jump should be a low to the ground boost of momentum (B Hopping)
	#Midair jumps allow for realignment of trajectory
	#The player should feel in control while midair, but should still have limited horizontal influence outside of jumping and grappling
#Grapple Mechanic
	#Pulls player towards viable object, and past the object
	#Player receives an extra jump after a successful grapple, which allows them to realign trajectory
	#Grapping disables players collision with a majority of in game set peices, excluding walls and platforms
	#The grapple should launch the player in the direction of the grappled object, and past that object
	#The trajectory of the launch is not direct, but rather an arc.
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

var velocity = Vector3() #The players velocity, currently maintains the y axis info between frames

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
	#Returns a vector 3 containing the normalized horizontal movement information
	return input_dir.normalized()

#Get the mouse movement input to control the camera
func _unhandled_input(event):
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		pivot.rotate_x(-event.relative.y * mouse_sens)
		rotate_y(-event.relative.x * mouse_sens)
		pivot.rotation.x = clamp(pivot.rotation.x, -1.2, 1.2)

#Runs the physics inputs every frame
func _physics_process(delta):
	velocity.y += gravity * delta #Adds new gravity to this frame
	var desired_velocity = get_input() * max_speed
	velocity.x = desired_velocity.x
	velocity.z = desired_velocity.z
	velocity = move_and_slide(velocity, Vector3.UP, true) #Finally move the player
