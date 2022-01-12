extends KinematicBody

#Last Change : 01/11/22

#ChangeLog:
	#Created enemy
	
#TODO
#Movement:
	#Flying enemy logs its initial height above the floor upon spawning, and ideally remains at that height
	#Moves horizontally towards player when the player is within line of sight (Raycast)
	#Wanders when the player is not within line of sight
#Grappling:
	#Does not collide with player while they're grappling

#BRAINSTORM
#I think that in order to acheive the flying enemy's movement successfully, I'll lock the vertical movement
#in order to prevent the enemy from getting too close to the ground, allowing for effective use of the grapple.
#Whether or not pathfinding nodes are necessary for moving, im not sure. I'll have to do more research into
#the topic.

onready var player = get_parent().get_node("Player")
export (float) var speed = 10

# Called when the node enters the scene tree for the first time.
func _ready():
	pass
	
func _physics_process(delta):
	var velocity = player.global_transform.origin - global_transform.origin
	velocity.y = 0
	move_and_slide(velocity.normalized() * speed)


