extends CharacterBody2D

@export_group("High Level Physics")
@export_range(200, 600, 100) var Speed = 400.0
@export_range(50, 200, 50) var Acceleration = 100
@export_range(1, 200) var Friction = 20.0
@export_range(200, 600, 50) var JumpVelocity = 400.0
@export_range(50, 1000, 50) var Ffspeed = 700
@export_range(0, 1000, 100) var FfTolerance = 375
@export_range(0.0, 0.3, 0.05) var JumpBufferTimer = 0.1
@export var MomentTimer = 0.2

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var direction: float

var ffPossible: bool = false
var inputEnabled: bool = true
var wallJumpPossible: bool = false



var storedVelocity: Vector2 = Vector2.ZERO

# maybe add the ability to transfer the direction of the velcoty you store?

@onready var JumpBuffer: SceneTreeTimer



func _physics_process(delta):

	# Add the gravity. 
	if not is_on_floor():
		velocity.y += gravity * delta

	# Handle jump. 
	HandleInput()
	Handlejump()
	HandleMoment()

	
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.

	if not is_on_floor() and velocity.y >= -FfTolerance and not ffPossible:

		ffPossible = true
		print("Fast Fall Possible")

	if is_on_floor():

		ffPossible = false
		wallJumpPossible = true


	move_and_slide()

func HandleMoment():

	if Input.is_action_just_pressed("moment"):
		if storedVelocity.is_equal_approx(Vector2.ZERO):
			storedVelocity = get_real_velocity()
			print("storing velocity")
			velocity = Vector2.ZERO
			disableGravityAndMovement()
			print("disabling gravity + movement for little while")
			await get_tree().create_timer(MomentTimer, false, true, true).timeout
			enableGravityAndMovement()
		else:
			disableGravityAndMovement()
			print("disabling gravity + movement for little while")
			velocity = storedVelocity
			print("using stored velocity")
			storedVelocity = Vector2.ZERO 
			print("setting store to 0")
			await get_tree().create_timer(MomentTimer, false, true, true).timeout
			enableGravityAndMovement()


func HandleInput():

	if inputEnabled:

		direction = Input.get_axis("left", "right")

		if direction:
			if is_on_floor():
				move_horizontal(direction)
			else:
				move_horizontal(direction * 0.75)
		else:
			if is_on_floor():
				velocity.x = move_toward(velocity.x, 0, Friction)
			else:
				velocity.x = move_toward(velocity.x, 0, Friction)
				

		if Input.is_action_just_pressed("down") and ffPossible:
			velocity.y += Ffspeed
			print("pressing down while fast fall is possible")

func move_horizontal(directionToMove):
		velocity.x = min(velocity.x + Acceleration , directionToMove * Speed)
	
 


func Handlejump():

	if Input.is_action_just_pressed("jump"):
		JumpBuffer = get_tree().create_timer(JumpBufferTimer, false, true, true)

	if JumpBuffer:
		if  not is_zero_approx(JumpBuffer.time_left):
			if is_on_floor():
				velocity.y = -JumpVelocity
			if is_on_wall() and wallJumpPossible:
				WallJump(get_wall_normal().x)
				wallJumpPossible = false
				print(get_wall_normal())



func disableGravityAndMovement():
	gravity = 0
	inputEnabled = false


func enableGravityAndMovement():
	gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
	inputEnabled = true


func WallJump(dir: float):
	var force := Vector2(JumpVelocity, -JumpVelocity)
	force.x *= dir

	if sign(velocity.x) != sign(force.x):
		force.x -= velocity.x
	
	if velocity.y < 0:
		force.y -= velocity.y

	velocity = force