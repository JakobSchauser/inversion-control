extends Node


var imove = true

var debug = false
# Declare member variables here. Examples:
# var a = 2
# var b = "text"

var REPEAT = "REPEAT"
var REVERSE = "REVERSE"
var FLIPY = "FLIPY"
var FLIPX = "FLIPX"
var FLIPXY = "FLIPXY"
var SCALE2 = "SCALE2"
var ONLYX="ONLYX"
var ONLYY="ONLYY"
var SWAP="SWAP"


onready var cam = $Camera2D
onready var campos = cam.position

var inventory = [REPEAT]

var height = 64
var width = 64

onready var movelabel = $movelist
var printlist = []

onready var originalmovelabel = $originalMoves
var transformedprintlist = []

var map = []

var col_start = Color("#06813c")
var col_red = Color("#e02a1d")

var textcol = col_start

var standon = " "

var pos = Vector2(21,25)
var gridsize = 64 

onready var level = $label

var allmoves = []
var moves = []
var cursor = 0

var itemcursor = 0
onready var itemlabel = $items
var itemmenu = false
var current_items = ["REPEAT","REVERSE","FLIPX", "FLIPY","FLIPXY"]
# Called when the node enters the scene tree for the first time.
func _ready():
	load_level()
	drawmove(Vector2())
	movelabel.text = ""
	originalmovelabel.text = ""	
	itemlabel.text = ""
	update_printlist([])
	update_original_printlist([])
	
	
	#pass # Replace with function body.

func load_level():
	var file = File.new()
	
	var first = true
	file.open("res://map.txt", File.READ)
	level.text = ""
	
	var lwidth = 0 
	while not file.eof_reached():
		var l = file.get_line()
		if first:
			first = false
			lwidth = len(l)
		else:
			l = l.substr(0,lwidth-1)
		map.append(l)
		level.text += l
		level.text += "\n"
			
	
	height = len(map)
	width = lwidth+1
	
	
	#for y in range(h):
	#	for x in range(w):
	
func charpos(pos):
	return pos.x + width*pos.y

func drawmove(v):
	var t = map
	t[pos.y-v.y][pos.x-v.x] = standon
	var S = t[pos.y][pos.x]
	if S == ".":
		 standon = " "
	elif S == " ":
		standon = "."
	else:
		standon = S
	t[pos.y][pos.x] = "@"
	
	var M = t
	
	if debug:
		M = map.duplicate(true)
		var acc = Vector2()
		for m in make_moves(moves, [REPEAT]):
			acc = acc + m
			M[pos.y + acc.y][pos.x + acc.x] = "'"
		
	
	
	
	
	var y = 10
	var x = 30
	var offy = floor((pos.y + min(0,v.y))/y)*y 
	var offx = floor((pos.x + min(0,v.x))/x)*x
	
	offy = pos.y - y/2
	#offx = pos.x - x/2
	
	
	var snit = M.slice(offy,offy+y).duplicate()
	var snit2 = ""
	for s in snit:
		snit2 += s.substr(offx,x+1) + "\n"
	level.text = snit2

	
func change_color(col):
	level.set("custom_colors/default_color", col)

func draw_ghost():
	var sofar = Vector2()
	for m in moves:
		sofar +=  m*gridsize
		#draw_circle(p.position + sofar,gridsize/2,Color.black)
		
func _draw():
	if debug:
		draw_ghost()
	
func domoves(moves_, dead=false):
	var time = 0.3
	var last_spot = null 
	if dead:
		time = 0.07
		change_color(col_red)		
	imove = false
	var i = 0
	for m in moves_:
		i += 1
		cursor = i
		update_printlist(moves_)
		
		lerpcam(m)
		# p.position += m*gridsize
		var pp = pos + m
		last_spot = map[pp.y][pp.x]
		if not map[pp.y][pp.x] in "Ob|+-":
			pos = pp
			if not dead:
				allmoves.append(m)
			drawmove(m)
			yield(get_tree().create_timer(time),"timeout")
		elif not dead:
			
			kill_player()
			return
	
	
	#imove = true
	var door = check_for_doors(pos)
	# reset stuff here
	if dead:
		standon  = "."
		
		imove = true 
		allmoves = []
		change_color(col_start)		
		moves = []
		movelabel.text = ""
		originalmovelabel.text = ""
	
	if not door and not dead:
		yield(get_tree().create_timer(0.5),"timeout")
		print("what")
		kill_player()
		
func mirror(moves, axis):
	var mm = []
	for m in moves:
		if axis == "x":
			m.x *= -1
		else:
			m.y *= -1
		mm.append(m)
	return mm

func transform_moves(moves, type):
	var m = moves.duplicate()
	match type:
		REPEAT:
			m = m
		REVERSE:
			m.invert()
		FLIPY:
			m = mirror(m, "y")
		FLIPX:
			m = mirror(m, "x")
		FLIPXY:
			m = mirror(mirror(m, "x"),"y")
		SCALE2:
			var new = []
			for mm in m:
				new.append(mm)
				new.append(mm)
			m = new
		ONLYX:
			var new = []
			for mm in m:
				mm.y = 0
				new.append(mm)
			m = new
		ONLYY:
			var new = []
			for mm in m:
				mm.x = 0
				new.append(mm)
			m = new
		SWAP:
			var new = []
			for mm in m:
				var mx = mm.x
				mm.x = mm.y
				mm.y = mx
				new.append(mm)
			m = new
	return m
	
	
func slowwrite(label,speed = 0.02):
	if label.visible_characters < len(label.text) and label.visible_characters != -1:
		label.visible_characters += 4
		yield(get_tree().create_timer(speed),"timeout")
		slowwrite(label,speed)
	
func make_moves(moves, move_types):
	var m = moves.duplicate()
	for t in move_types:
		m = transform_moves(m, t)
	return m

func kill_player():
	standon = " "
	domoves(make_moves(allmoves, [REVERSE, FLIPX, FLIPY]), true)

func make_str(lst):
	var t = ""
	for pt in lst:
		t += pt + "\n"
	return t
	
func vec2dir(vec):
	if vec.x < 0:
		return "left"
	if vec.x > 0:
		return "right"
	if vec.y < 0:
		return "up"
	return "down"

func update_printlist(_moves):
	printlist = ["TRANSFORMED"]
	var i = 0
	for m in _moves:
		var cc = " "
		if i == cursor:
			cc = ">"
		i += 1		
		printlist.append(cc + vec2dir(m).to_upper())
	movelabel.text = make_str(printlist)

func update_original_printlist(_moves):
	printlist = ["MOVES"]
	for m in _moves:
		printlist.append(vec2dir(m).to_upper())
	originalmovelabel.text = make_str(printlist)

func check_for_doors(_pos):
	var looks = [Vector2(-1,0),Vector2(1,0),Vector2(0,-1),Vector2(0,1)]
	for l in looks:
		var see = map[_pos.y + l.y][_pos.x + l.x]
		if see in "O":
			pos += l*2
			drawmove(l*2)
			allmoves.append(l*2)
			
			itemmenu = true
			itemcursor = 0
			return true
	return false

func lerpcam(dir):
	if dir != Vector2():
		cam.position += dir
	else:
		cam.position = lerp(cam.position,campos,0.1)


func _process(delta):
	if (Input.is_action_just_pressed("restart")):
		kill_player()
	
	lerpcam(Vector2())
	if itemmenu:
		itemlabel.show()
		var pt = ""
		var i = 0
		for it in current_items:
			var cc = " "
			if i == itemcursor:
				cc = ">"
				
			i += 1
				
			pt += cc + it + "	"
		itemlabel.text = pt
		update_printlist(make_moves(moves, [current_items[itemcursor]]))
		if(Input.is_action_just_pressed("ui_left")):
			itemcursor = max(0,itemcursor-1)
		elif (Input.is_action_just_pressed("ui_right")):
			itemcursor = min(len(current_items)-1,itemcursor+1)
		elif (Input.is_action_just_pressed("ui_accept")):
			itemmenu = false
			domoves(make_moves(moves, [current_items[itemcursor]]))
			itemlabel.text = ""
			
			
		return
	if Input.is_action_just_pressed("debug"):
		debug = !debug
		imove = debug
	if not imove:
		return
		
	
		
	var move = Vector2()
	if (Input.is_action_just_pressed("ui_up")):
		move.y = -1
	elif(Input.is_action_just_pressed("ui_down")):
		move.y = 1
	elif(Input.is_action_just_pressed("ui_left")):
		move.x = -1
	elif (Input.is_action_just_pressed("ui_right")):
		move.x = 1
	elif (Input.is_action_just_pressed("ui_accept")):
		level.visible_characters = 0
		slowwrite(level,0.0001)	
		print("Here")
		if debug:
			domoves(make_moves(moves, [REPEAT]))
	elif (Input.is_action_just_pressed("ui_cancel")):
		moves = []
	elif (Input.is_action_just_pressed("b")):
		standon = "b"
	elif (Input.is_action_just_pressed("save")):
		standon = "s"
	elif (Input.is_action_just_pressed("backspace")):
		var mmm = moves.back()
		if mmm:
			pos -= mmm
			if standon == ".":
				standon = " " 
			allmoves.pop_back()
			moves.pop_back()
			drawmove(-mmm)
			update_printlist(moves)
			update_original_printlist(moves)
					
	if move != Vector2():
		lerpcam(-2*move)
		var mv = pos + move
		
		var goto = map[mv.y][mv.x]
		if not goto in "b|+-." or debug:
			pos += move
			moves.append(move)
			allmoves.append(move)
			drawmove(move)
			update_printlist(moves)
			update_original_printlist(moves)
			check_for_doors(mv)
		else:
			kill_player()
