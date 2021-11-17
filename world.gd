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


var globaldead = false


var deletion = false

var menuselectplayer = AudioStreamPlayer.new()
var writeplayer = AudioStreamPlayer.new()


var walksound = preload("sfx/compute.wav")
var deathsound = preload("sfx/sfx1.wav")
var deathmovesound = preload("sfx/sfx4.wav")
var deletesound = preload("sfx/sfx3.wav")
var pickupsound = preload("sfx/sfx7.wav")
var menuselectsound = preload("sfx/sfx6.wav")
var menumovesound = preload("sfx/sfx5.wav")
var printsound = preload("sfx/computer.wav")



onready var glowint = $WorldEnvironment.environment.glow_intensity
onready var glowstr = $WorldEnvironment.environment.glow_strength
onready var warp = $CRT.material.get_shader_param("warp_amount")
onready var abe = $CRT.material.get_shader_param("aberration")
		

onready var audio = $AudioStreamPlayer


var running_intro = true

onready var cam = $Camera2D
onready var campos = cam.position

var inventory = [REPEAT]

var height = 64
var width = 64

onready var movelabel = $movelist
var printlist = []

onready var titlelabel = $title

onready var originalmovelabel = $originalMoves
var transformedprintlist = []

var map = []
var time = 0

var col_start = Color("#06813c")
var col_red = Color("#e02a1d")

var textcol = col_start

var standon = " "

var pos = Vector2(31,25)
#var endpos = Vector2(31,25-10)
var endpos = Vector2(15,1)

var gridsize = 64 

onready var level = $label

var allmoves = []
var moves = []
var cursor = 0

var itemcursor = 0
onready var itemlabel = $items
var itemmenu = false
var current_items = ["REPEAT"]
# Called when the node enters the scene tree for the first time.
func _ready():
	add_child(menuselectplayer)
	add_child(writeplayer)
	writeplayer.stream = printsound
	
	
	load_level()
	drawmove(Vector2())
	movelabel.text = ""
	originalmovelabel.text = ""	
	itemlabel.text = ""
	update_printlist([])
	update_original_printlist([])
	
	#intro()
	imove = true
	running_intro = false

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

func get_cell(pos):
	return Vector2(floor(pos.x / 10)*10, floor(pos.y / 10) *10)


func drawmove(v):
	# var d = sqrt((endpos.x - pos.x)*(endpos.x - pos.x) + (endpos.y - pos.y)*(endpos.y - pos.y))
	
	if get_cell(pos) == get_cell(endpos):
		
		$WorldEnvironment.environment.glow_intensity = 1.1
		$WorldEnvironment.environment.glow_strength = 0.9
		$CRT.material.set_shader_param("warp_amount", 5) 
		$CRT.material.set_shader_param("aberration", 0.15) 
		
	
	
	#var maxd = sqrt(10)
	#if d <= maxd:
	#	$WorldEnvironment.environment.glow_intensity = lerp($WorldEnvironment.environment.glow_intensity,(maxd-d)/maxd*30,0.5)
	#	$WorldEnvironment.environment.glow_strength =  lerp($WorldEnvironment.environment.glow_strength,(maxd-d)/maxd*1.3,0.5)
		#$CRT.material.set_shader_param("warp_amount", sqrt(maxd-d)/maxd*10 + warp) 
		#$CRT.material.set_shader_param("aberration", sqrt(maxd-d)/maxd*0.4 + abe) 
		
		
	map[endpos.y][endpos.x] = "$"
	var t = map
	
	if deletion:
		standon = " "
		deletion = false
	t[pos.y-v.y][pos.x-v.x] = standon
	var S = t[pos.y][pos.x]
	

	if S == " ":
		standon = "."
	else:
		standon = S
		
	t[pos.y][pos.x] = "."#@
	
	var M = t
	
	if debug:
		M = map.duplicate(true)
		var acc = Vector2()
		for m in make_moves(moves, [REPEAT]):
			acc = acc + m
			M[pos.y + acc.y][pos.x + acc.x] = "'"
		
	
	
	
	
	#_______
	
	var y = 10
	var x = 10
	var offy = floor((pos.y + min(0,v.y))/y)*y 
	var offx = floor((pos.x + min(0,v.x)) /x)*x
	
	# offy = pos.y - y/2
	#offx = pos.x - x/2
	
	
	var snit = M.slice(offy,offy+y).duplicate()
	var snit2 = ""
	for s in snit:
		snit2 += s.substr(offx-10,x+1 + 20) + "\n"
	level.text = snit2
	#_________
	
	
func change_color(col):
	level.set("custom_colors/default_color", col)
	movelabel.set("custom_colors/default_color", col)
	titlelabel.set("custom_colors/default_color", col)

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
		if dead:
			deletion = true
			audio.stream = deathmovesound
		else:
			audio.stream = walksound
		audio.play()
		
		i += 1
		
		
		if not dead:
			cursor = i
			update_printlist(moves_)
		else:
			cursor = len(allmoves)-i
			update_printlist(allmoves.slice(0,cursor))
		#lerpcam(m)
		# p.position += m*gridsize
		var pp = pos + m
		last_spot = map[pp.y][pp.x]
		if not map[pp.y][pp.x] in "#Ob|+-":
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
		globaldead = false
		update_printlist(moves)
		
	if not door and not dead:
		if last_spot == " ":
			yield(get_tree().create_timer(0.5),"timeout")
			kill_player()
		else:
			audio.stream = pickupsound
			audio.play()
			if last_spot == "1":
				current_items.append("REVERSE")
			elif last_spot == "2":
				current_items.append("FLIPX")
			elif last_spot == "3":
				current_items.append("FLIPY")
			elif last_spot == "4":
				current_items.append("FLIPXY")
			standon  = " "
			yield(get_tree().create_timer(2),"timeout")
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
	
func play_sound(s):
	var a = AudioStreamPlayer.new()
	a.stream = s
	add_child(a)
	a.play()
	yield(a, "finished")
	a.queue_free()



func write(st):
	var stt = "" 
	for s in st:
		if s != "#":
			stt += s
	
	level.text = stt.to_upper()
	
	var j = 0
	for s in range(len(st)):
		var time = 0.01
		var thelastjthatwas = j
		j += 1
		if st[s] == "\n":
			j -= 1
			time = 0.5
		if st[s] == "#":
			time = 0.5
			j -= 1
		if st[s] == ".":
			time = 0.2
		
		
		
		if j != thelastjthatwas and j % 1 == 0 and true:
			play_sound(printsound)
		
			
		
		yield(get_tree().create_timer(time),"timeout")
		level.visible_characters = j 
	
	# print("whatt")
	running_intro = false
	imove = true
	level.visible_characters = -1
	drawmove(Vector2())

	level.visible_characters = 0
	slowwrite(level,0.0001)	
	movelabel.visible_characters = 0
	slowwrite(movelabel,0.1)
	

func intro():
	titlelabel.text = ""
	movelabel.text = ""
	running_intro = true
	
	imove = false
	level.visible_characters = 0
	
	yield(get_tree().create_timer(2),"timeout")
	write("\nbooting systems#...#\nbooting subsystems#...#\nuser name:# schrunkin#\npassword:# ********#\nincorrect password,# try again.#\nuser name:# schrunkin#\npassword:## ***##\naccess granted.#\nloading gwj2021 entry#...###")
	
	
func intro_text(t, spd=0.02):
	level.text = t.to_upper()
	slowwrite(level, spd)
	





func slowwrite(label,speed = 0.02):
	if label.visible_characters < len(label.text) and label.visible_characters != -1:
		label.visible_characters += 12
		play_sound(printsound)
		yield(get_tree().create_timer(speed),"timeout")
		slowwrite(label,speed)
	else:
		label.visible_characters = -1
	
func make_moves(moves, move_types):
	var m = moves.duplicate()
	for t in move_types:
		m = transform_moves(m, t)
	return m

func kill_player():
	globaldead = true
	play_sound(deathsound)
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
	printlist = []
	var i = 0
	for m in _moves:
		var cc = " "
		if i == cursor:
			cc = ">"
		i += 1
		printlist.append(cc + vec2dir(m).to_upper())

	var words_per_line = 10
		
	var firsthalf = printlist.slice(0,words_per_line-1)
	var secondhalf = printlist.slice(words_per_line,-1)
	
	var finalrows = ["MOVES:"]
	for fh in range(len(firsthalf)):
		if fh < len(secondhalf):
			var ws = ""
			for f in range(7-len(firsthalf[fh])):
				ws += " "
			finalrows.append(firsthalf[fh] + ws + secondhalf[fh])
		else:
			finalrows.append(firsthalf[fh])
	movelabel.text = make_str(finalrows)

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
			
			# timer = Timer.new()
			flick()
			
			itemmenu = true
			itemcursor = 0
			
			level.visible_characters = 0
			slowwrite(level,0.0001)	
			movelabel.visible_characters = 0
			slowwrite(movelabel,0.1)
			
			return true
	return false

func lerpcam(dir):
	if dir != Vector2():
		cam.position += dir
	else:
		cam.position = lerp(cam.position,campos,0.1)


func flick():
	itemlabel.hide()
	yield(get_tree().create_timer(1),"timeout")
	itemlabel.show()	
	slowwrite(itemlabel, 0.0001)
	play_sound(menumovesound)

func _process(delta):
	
	#if Input.is_action_just_pressed("b"):
	#	drawmove(Vector2())
	time += delta
	if running_intro:
		return
	if (Input.is_action_just_pressed("restart")):
		kill_player()
	
	
	if imove:
		titlelabel.text = "RECORDING NEW MOVES"
	if itemmenu:
		titlelabel.text = "CHOOSE A TRANSFORMATION"
	elif not imove and globaldead:
		titlelabel.text = "RETURNING"
	elif not imove:
		titlelabel.text = "PLAYBACK OF MOVES"
	elif len(moves) > 19:
		titlelabel.text = "OUT OF MEMORY - PRESS BACKSPACE"
			
		
	lerpcam(Vector2())
	if itemmenu:
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
		if itemlabel.visible:
			if(Input.is_action_just_pressed("ui_left")):
				var bf = itemcursor
				itemcursor = max(0,itemcursor-1)
				if bf != itemcursor:
					audio.stream = menumovesound
					audio.play()
					
			elif (Input.is_action_just_pressed("ui_right")):
				var bf = itemcursor						
				itemcursor = min(len(current_items)-1,itemcursor+1)
				if bf != itemcursor:
					audio.stream = menumovesound
					audio.play()
			elif (Input.is_action_just_pressed("ui_accept")):
				menuselectplayer.stream = menuselectsound
				menuselectplayer.play()
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
		audio.stream = deletesound
		deletion = true
		audio.play()
		var mmm = moves.back()
		if mmm:
			pos -= mmm
			standon = " "
			allmoves.pop_back()
			moves.pop_back()
			drawmove(-mmm)
			update_printlist(moves)
			update_original_printlist(moves)
	
	if len(moves) > 19:
		move = Vector2()
	
	if move != Vector2():
		audio.stream = walksound
		audio.pitch_scale = rand_range(1,1.01)
		audio.play()
		
		#lerpcam(-2*move)
		var mv = pos + move
		
		var goto = map[mv.y][mv.x]
		if not goto in "#b|+-." or debug:
			pos += move
			moves.append(move)
			allmoves.append(move)
			drawmove(move)
			update_printlist(moves)
			update_original_printlist(moves)
			check_for_doors(mv)
		else:
			lerpcam(-move*20)
			kill_player()
