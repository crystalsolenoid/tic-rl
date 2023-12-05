// title:  Tic-RL: REFACTORED EDITION
// author: Quinten Konyn
// desc:   Roguelike Engine for TIC-80
// script: wren

// note: uses banks

class Game is TIC{

	construct new(){ // init
		_world = World.new()
		_gui = GUI.new(_world)
		_clock = TIC.time()
	}

	TIC(){ // main loop
		_clock = TIC.time()

		if(_world.next){
			_world.update()
			_gui.update(_world.player.pos)
		}

		TIC.cls()
		_gui.render()

		_world.next = UI.getInput(_world)

	}

}

// <CODE1>
// Display Library

class Renderer{
	construct new(ch, vi, c1){
		_ch = ch
		_vi = vi
		_c1 = c1
	}
	ch { _ch }
	vi { _vi }
	c1 { _c1 }
}

// Mob Renderer Objects
var PLAYER_RENDER=Renderer.new("@",1,9)
var GHOST_RENDER=Renderer.new("&",2,11)

class Window{
	construct new(level){
		_level = level
	}
	buf{2}
	frameCol{Palette.ui}
	render(){
		render_border()
		render_contents()
	}
	update(pos){
		update_contents(pos)
	}
	render_border(){
		var x0 = offs[0] - buf
		var y0 = offs[1] - buf
		var x1 = w * px + x0 - 1 + 2 * buf
		var y1 = h * px + y0 - 1 + 2 * buf
		TIC.line(x0, y0, x0, y1, frameCol)
		TIC.line(x0, y0, x1, y0, frameCol)
		TIC.line(x1, y0, x1, y1, frameCol)
		TIC.line(x0, y1, x1, y1, frameCol)
	}
	render_contents(){
		for(i in 0.._buffer.count-1){
			var t
			if(ascii){
				if(i%2==0){
					t = _buffer[i]
					TIC.rect(t[0], t[1], t[2], t[3], t[4])
				} else {
					t = _buffer[i]
					printc(t[0], t[1], t[2], t[3])
				}
			} else {
				t = _buffer[i]
				TIC.rect(t[0], t[1], t[2], t[3], t[4])
			}
		}
	}
	display_off(pos){
		var o = [0,0]
		// simple offset
		o[0] = pos[0] - (w/2).floor - 1
		o[1] = pos[1] - (h/2).floor - 1
		// boundaries
		if(pos[1]*2 < h){
			o[1] = 0 // top
		}
		if(pos[1] > _level.dims[1] - (h/2).floor){
		 o[1] = _level.dims[1] - h // bottom
		}
		if(pos[0]*2 < w){
			o[0] = 0 // left
		}
		if(pos[0] > _level.dims[0] - (w/2).floor){
		 o[0] = _level.dims[0] - w // right
		}
		// level too small
		if(h >= _level.dims[1]){
			o[1] = ((_level.dims[1] - w)/2).floor // too short
		}
		if(w >= _level.dims[0]){
			o[0] = ((_level.dims[0] - h)/2).floor // too thin
		}
		return o
	}
	update_contents(pos){
		_buffer = []
		var d_offs = display_off(pos)
		var i
		var j
		var tile
		for (id in 1..w){
			for (jd in 1..h){
				i = id + d_offs[0]
				j = jd + d_offs[1]
				tile = _level[i,j]
				update_tile(tile, id-1, jd-1)
			}
		}
	}
	update_tile(tile, i, j){
		var rx = px * i + offs[0]
		var ry = px * j + offs[1]
		var x = px * (i + 0.5) + offs[0]
		var y = px * (j + 0.5) + offs[1]

		if (!tile){tile = Tile.new()} // use VOID tile

		var ch = tile.ch
		var col = [tile.c1, tile.c2]
		var mob = tile.mobSeen

		// mob drawing here
		if (mob){
			ch = mob.rend.ch
			col[0] = mob.rend.c1
		}

		// lighting here
			col = Palette.illumCol(col, tile.vi, tile.se)
			if(!ascii){
				if(tile.se || Debug.eagleEye){
					// floorif not seen
					col[1] = Palette.mini_rm
					if(tile.vi < 5) col[1] = Palette.mini_vi
					// walls always the same color
					if(tile.so) col[1] = Palette.mini_wall
					if(mob) col[1] = 6//Palette[tile.mob.rend.c1,1]
					if(mob is Player) col[1] = Palette.mini_player
				}
			}
		_buffer.add([rx, ry, px, px, col[1]])
		if(ascii) _buffer.add([ch, x, y, col[0]])
	}
	printc(ch, x, y, col){ // TODO put this in renderer
		var w = TIC.print(ch,0,-8)
		TIC.print(ch, x-(w/2)+1, y-2, col || 15)
	}
}

class MainWindow is Window{
	construct new(level){
		super(level)
	}
	w{17}
	h{17}
	px{7}
	offs{
		return [((240-w*px)/2).floor,
										((136-h*px)/2).floor]
	}
	ascii{true}
}

class MiniMap is Window{
	construct new(level, parent){
		super(level)
		_parent = parent
	}
	w{35}
	h{35}
	px{1}
	offs{
		return [ _parent.offs[0] +
									 	_parent.w * _parent.px +
									  _parent.buf + 5,
									  _parent.offs[1]]
	}
	ascii{false}
}

class GUI{
	construct new(world){
		_mainWindow = MainWindow.new(world.level)
		_miniMap = MiniMap.new(world.level, _mainWindow)
	}
	render(){
		_mainWindow.render()
		_miniMap.render()
	}
	update(pos){
		_mainWindow.update(pos)
		_miniMap.update(pos)
	}
}

class Palette{
	static ui{1}
	static mini_wall{1}
	static mini_rm{4}
	static mini_vi{9}
	static mini_player{14}
	static fg{9}
	static bg{15}
	static rm{1}
	static [c,d]{ pal[c][(d..pal[c].count-1).min] }
	static pal{
		if(!__pal){
			__pal = [[0],
											 [1,1,0],
												[2,2,0],
												[3,2,0],
												[4,1,0],
												[5,0],
												[6,4,0],
												[7,3,2,0],
												[8,2,0],
												[9,9,4,1,0],
												[10,7,3,2,0],
												[11,5,4,1,0],
												[12,4,1,0],
												[13,8,2,0],
												[14,9,4,1,0],
												[15,14,9,4,1,0]]
		}
		return __pal
	}
	static illumCol(col, vi, se){
		var iCol = [0, 0]
		// fg
		iCol[0] = this[col[0], vi]
		// bg
		iCol[1] = this[col[1], vi]
		// seen before?
		if(vi >= Raytracer.maxVi && se){
			iCol[0] = rm
		}
		return iCol
	}
}

// </CODE1>

// <CODE2>
// Map Library

class World{
	construct new(){
		_turn = -1
		_next = true
		_player = Player.new()
		_level = Level.new()
		_level.mapGen()
		_level.placeMob(_player)
	}
	update(){
		if(_next){
			_level.updateMobs()
			Raytracer.rayTrace(_level, _player)
			_turn = _turn + 1
			_next = false
		}
	}
	turn{_turn}
	next{_next}
	next =(value){_next = value}
	level{_level}
	player{_player}
}

class Level{
	construct new(w, h){
		_dims = [w, h]
		_data = []
		_mobs = []
	}
	construct new(){
		_dims = [LEVEL_WIDTH, LEVEL_HEIGHT]
		_data = []
		_mobs = []
	}
	mapGen(){
		initData(Empty)
		addWalls()
		addRandom()
		RoomMapper.mapGen(this)
		for(i in 0..5) placeMob(Ghost.new())
	}
	dims{_dims}
	w{_dims[0]}
	h{_dims[1]}
	count{_data.count}
	idx(x, y){x - 1 + (y - 1) * _dims[0]}
	inBounds(x, y){
		var xb = x>0 && x<=_dims[0]
		var yb = y>0 && y<=_dims[1]
		return xb && yb
	}
	[x, y]{
		if(inBounds(x, y)){
			return _data[idx(x,y)]
		} else {
			return null
		}
	}
	[x, y]=(value){
		if(inBounds(x, y)){
			_data[idx(x, y)] = value
		}
	}
	[pos]{
		return this[pos[0],pos[1]]
	}
	initData(tile){
		for(i in 1.._dims[0]){
			for(j in 1.._dims[1]){
			 _data.add(tile.new())
			}
		}
	}
	initBool(bool){
		for(i in 1.._dims[0]){
			for(j in 1.._dims[1]){
			 _data.add(bool)
			}
		}
	}
	addWalls(){ // adds boundary walls
		for(i in 1.._dims[0]){
			this[i, 1] = Wall.new()
			this[i, _dims[1]] = Wall.new()
		}
		for(j in 2.._dims[1]-1){
			this[1, j] = Wall.new()
			this[_dims[0], j] = Wall.new()
		}
	}
	addRandom(){
		for(i in 1.._dims[0]){
			for(j in 1.._dims[1]){
				if(RANDOM_LEVEL_GEN.int(10) == 0){
					this[i, j] = Wall.new()
				}
			}
		}
	}
	placeMob(mob){
		if(mob.pos == null){ mob.pos = randomFree() }
		if(mob.pos){
			mob.level = this
			this[mob.pos[0], mob.pos[1]].mob = mob
			_mobs.add(mob)
		} else {
			TIC.trace("monster overflow")
		}
	}
	updateMobs(){
		for(mob in _mobs) mob.act()
	}
	moveMob(pos, dir){
		var mob = this[pos[0], pos[1]].mob
		this[pos[0], pos[1]].mob = null
		this[pos[0] + dir[0], pos[1] + dir[1]].mob = mob
 }
	tryMove(mob, dir){
		if(!checkSolid([mob.pos[0] + dir[0],
																	mob.pos[1] + dir[1]])){
			moveMob(mob.pos, dir)
			return true
		}
	}
	checkSolid(pos){
		return !this[pos] || this[pos].so || this[pos].mob
	}
	updateVisibility(vis){
		for(i in 1.._dims[0]){
			for(j in 1.._dims[1]){
				this[i, j].vi = vis[i, j]
			}
		}
	}
	mapFromProc(map){
		_data = List.filled(w * h, null)
		for(i in 1.._dims[0]){
			for(j in 1.._dims[1]){
				if(map[i, j]){
					this[i, j] = Wall.new()
				} else {
					this[i, j] = Empty.new()
				}
			}
		}
	}
	randomFree(){
		for(tries in 1..5000){
			var i = RANDOM_LEVEL_GEN.int(w)
			var j = RANDOM_LEVEL_GEN.int(h)
			if(!checkSolid([i, j])) return [i, j]
		}
		return false
	}
}

class Tile{
	construct new(){
		_vi = 5
		_se = false
	}
	ch {"?"}
	c1 {Palette.fg} // foreground color
	c2 {Palette.bg} // background color
	so {false} // solid
	op {false} // opaque
	vi {_vi} // currently visible
	vi=(value){
		_vi = value
		_se = _se || visible
		if(visible) _mobseen = _mob
	}
	visible{ _vi < Raytracer.maxVi }
	se {_se} // seen previously
	mob {_mob} // mob occupying tile
	mob=(value){
		_mob = value
		if(visible) _mobseen = _mob
	}
	mobSeen { _mobseen }
}

class Wall is Tile{
	construct new(){super()}
	ch {"#"}
	so {true}
	op {true}
}

class Empty is Tile{
	construct new(){super()}
	ch {"`"}
}

// </CODE2>

// <CODE3>
// Mobs Library

class Mob{
	construct new(x, y, render){
		_pos = [x, y]
		_rend = render
	}
	construct new(render){
		_pos = null
		_rend = render
	}
	rend { _rend }
	pos { _pos }
	pos=(value) { _pos = value }
	level=(value){ _level = value }
	move(dir){
		if(_level.tryMove(this, dir)){
			_pos[0] = _pos[0] + dir[0]
			_pos[1] = _pos[1] + dir[1]
			return true
	 }
	}
}

class Player is Mob{
	construct new(){
		super((LEVEL_WIDTH/2).ceil,
		      (LEVEL_HEIGHT/2).ceil,
								PLAYER_RENDER)
	}
	vis{ 3 }
	dim{ 1 }
	act(){ false }
}

class Ghost is Mob{
	construct new(){ super(GHOST_RENDER) }
	act(){
		move(RANDOM_MONSTER_AI.sample(TwoVector.cardinal))
	}
}

// </CODE3>

// <CODE4>

// UI

class UI{
	static getInput(world){
		__hold = 30
		__period = 5
		var mob = world.player
		// UP
		if(TIC.btnp(0, __hold, __period)){
			return mob.move([0, -1])
		}
		// DOWN
		if(TIC.btnp(1, __hold, __period)){
			return mob.move([0, 1])
		}
		// LEFT
		if(TIC.btnp(2, __hold, __period)){
			return mob.move([-1, 0])
		}
		// RIGHT
		if(TIC.btnp(3, __hold, __period)){
			return mob.move([1, 0])
		}
	}
}

// </CODE4>

// <CODE5>

// Algorithms

class Raytracer{
	static rayTrace(lv, p){
		__lv = lv
		__p = p
		newLocal()
		updateDenseOpaque()
		denseRayTrace()
		compressSpatialTable()
		distanceGradient()
		lv.updateVisibility(__vis)
	}
	static c{ 3 } //cdens must be odd
	static rayPower{ 2 }
	static maxVi{ 5 }
	static newLocal(){
		__l = Level.new(__lv.w,__lv.h)
		__l.initBool(true)
  for(y in 1..__lv.h){
			for(x in 1..__lv.w){
				if(__lv[x, y]){
					__l[x, y] = __lv[x, y].op
				}
			}
		}
	}
	static updateDenseOpaque(){
		var wc = (c-1)/2
		var xc
		var yc
		__d = Level.new(__l.w*c, __l.h*c)
		__d.initBool(false)
		for(y in 1..__l.h){
			for(x in 1..__l.w){
				if(__l[x, y]){
					// cender coords
					xc = x*c - wc
					yc = y*c - wc
					// diamonds
					for(xx in 0..wc){
						for(yy in -wc+xx..0){
							__d[xc+xx, yc+yy] = true // NE
						}
					}
					for(xx in -wc..0){
						for(yy in -wc-xx..0){
							__d[xc+xx, yc+yy] = true // NW
						}
					}
					for(xx in 0..wc){
						for(yy in 0..wc-xx){
							__d[xc+xx, yc+yy] = true // SE
						}
					}
					for(xx in -wc..0){
						for(yy in 0..wc+xx){
							__d[xc+xx, yc+yy] = true // SW
						}
					}
					// bevels
					if(__l[x, y-1]){ // if north opaque
						for(xx in -wc..0){
							for(yy in 0..wc+xx){
								__d[xc+wc+xx, yc-wc+yy] = true // northeast
							}
						}
						for(xx in 0..wc){
							for(yy in 0..wc-xx){
								__d[xc-wc+xx, yc-wc+yy] = true // northwest
							}
						}
					}
					if(__l[x, y+1]){ // if south opaque
						for(xx in -wc..0){
							for(yy in -wc-xx..0){
								__d[xc+wc+xx, yc+wc+yy] = true // southeast
							}
						}
						for(xx in 0..wc){
							for(yy in -wc+xx..0){
								__d[xc-wc+xx, yc+wc+yy] = true // southwest
							}
						}
					}
					if(__l[x+1, y]){ // if east opaque
						for(xx in -wc..0){
							for(yy in 0..wc+xx){
								__d[xc+wc+xx, yc-wc+yy] = true // northeast
							}
						}
						for(xx in -wc..0){
							for(yy in -wc-xx..0){
								__d[xc+wc+xx, yc+wc+yy] = true // southeast
							}
						}
					}
					if(__l[x-1, y]){ // if west opaque
						for(xx in 0..wc){
							for(yy in 0..wc-xx){
								__d[xc-wc+xx, yc-wc+yy] = true // northwest
							}
						}
						for(xx in 0..wc){
							for(yy in -wc+xx..0){
								__d[xc-wc+xx, yc+wc+yy] = true // southwest
							}
						}
					}
				}
			}
		}
	}
	static denseRayTrace(){
		__dvis = Level.new(__l.w*c, __l.h*c)
		__dvis.initBool(false)
		var boundCirc = densenPointTable(Math.circle(__p.pos[0], __p.pos[1], __p.vis*2))
		var off = (c-1)/2
		for(v in boundCirc){
			denseRay(__p.pos[0]*c-off,__p.pos[1]*c-off,
												v[0],v[1])
		}
	}
	static densenPointTable(t){
		var tt = []
		var x
		var y
		for(v in t){
			x = v[0]
			y = v[1]
			for(xx in (x-1)*c+1..x*c){
				for(yy in (y-1)*c+1..y*c){
					tt.add([xx,yy])
				}
			}
		}
		return tt
	}
	static denseRay(x1, y1, x2, y2){
		var dx = 2 * (x2 - x1).abs
		var dy = 2 * (y2 - y1).abs
		var ix = (x2 - x1) > 0 && 1 || -1 // ???
		var iy = (y2 - y1) > 0 && 1 || -1 // ???
		var er
		var power = rayPower
		__dvis[x1, y1] = true
		if(dx >= dy){
			er = dy - dx/2
			while(x1 != x2 && power > 1){
				if(er>0 || ((er == 0)&&(ix>0))){
					er = er - dx
					y1 = y1 + iy
				}
				er = er + dy
				x1 = x1 + ix
				__dvis[x1, y1] = true
				if(__d[x1, y1]) power = power - 1
			}
		} else {
			er = dx - dy/2
			while(y1 != y2 && power > 1){
				if(er>0 || ((er==0)&&(iy>0))){
					er = er - dy
					x1 = x1 + ix
				}
				er = er + dx
				y1 = y1 + iy
				__dvis[x1, y1] = true
				if(__d[x1, y1]) power = power - 1
			}
		}
	}
	static compressSpatialTable(){
			__vis = Level.new(__l.w, __l.h)
			__vis.initBool(false)
			// only using mode 'or' from lua version
			var btrue
			for(y in 1..__l.h){
				for(x in 1..__l.w){
					btrue = false
					for(xx in (x-1)*c+1..x*c){
						for(yy in (y-1)*c+1..y*c){
							btrue = btrue || __dvis[xx, yy]
						}
					}
					__vis[x, y] = btrue
				}
			}
	}
	static distanceGradient(){
		var dist
		var vis
		for(i in 1..__vis.w){
			for(j in 1..__vis.h){
				dist = ((i-__p.pos[0]).pow(2)+(j-__p.pos[1]).pow(2)).sqrt
				vis = ((dist-__p.vis+2*__p.dim..__p.dim).max/__p.dim).floor
				if(!__vis[i, j]){
					vis = (maxVi+1-__p.vis+2*__p.dim..__p.dim).max
				}
				__vis[i, j] = vis
			}
		}
	}
}

class TwoVector{
	construct new(x, y){
		_x = x
		_y = y
	}
	construct new(twoVect){
		_x = twoVect.x
		_y = twoVect.y
	}
	x{ _x }
	y{ _y }
	+(other){ TwoVector.new(_x + other.x, _y + other.y) }
	*(other){ TwoVector.new(_x * other, _y * other) }
	[i]{ i == 0 ? _x : _y }
	static cardinal{
		if(!__cardinal){
			__cardinal = [ TwoVector.new(0, 1),
																		TwoVector.new(0,-1),
																		TwoVector.new(1, 0),
																		TwoVector.new(-1,0) ]
		}
		return __cardinal
	}
}

class Grid{
	construct new(dims, fill){
		_dims = dims
		_default = null
		_data = List.filled(dims[0] * dims[1], fill)
	}
	construct new(width, height, fill){
		return Grid.new([width, height], fill)
	}
	construct new(width, height, fill, default){
		Grid.new([width, height], fill)
		_default = default
	}
	construct new(grid){
		_dims = [grid.w, grid.h]
		_default = grid.default
		_data = []
		for(i in grid.data){
			_data.add(i)
		}
	}
	w{ _dims[0] }
	h{ _dims[1] }
	idx(x, y){x - 1 + (y - 1) * _dims[0]}
	inBounds(x, y){
		var xb = x>0 && x<=_dims[0]
		var yb = y>0 && y<=_dims[1]
		return xb && yb
	}
	[x, y]{
		if(inBounds(x, y)){
			return _data[idx(x,y)]
		} else {
			return _default
		}
	}
	[x, y]=(value){
		if(inBounds(x, y)){
			_data[idx(x, y)] = value
		} else {
			TIC.trace("bound error")
		}
	}
	[pos]{ this[pos[0],pos[1]] }
	[pos]=(value){ this[pos[0],pos[1]] = value }
	default{_default}
	data{_data}
	count(value){
		var ct = 0
		for(i in _data){
			if(i == value)ct = ct + 1
		}
		return ct
	}
}

class RoomMapper{
	static mapGen(lv){
		// seed tracking
		__seed = RANDOM_SEED_GEN.int(500)
		TIC.trace("MapGen Seed: "+__seed.toString)
		__rnd = Random.new(__seed)
		// make a level
	 var map = newMap(lv.dims, true)
		digBox((LEVEL_WIDTH/2).ceil-2,
		      (LEVEL_HEIGHT/2).ceil-2,
								4, 4, map)
		fillRooms(10, 6, 12, map)
  fillRooms(100, 4, 6, map)
		// try many hallways
		var bestLength = 999999999999
		var bestMap = null
		for(i in 0..10){
			var activeLevel = Grid.new(map)
			fillMaze(activeLevel)
			unifyZones(10, activeLevel)
			unwindMaze(activeLevel)
			var hallwayLength = activeLevel.count(false)
			if(hallwayLength < bestLength){
				bestLength = hallwayLength
				bestMap = activeLevel
			}
		}
		lv.mapFromProc(bestMap)
	}
	static newMap(dims, fill){
		return Grid.new(dims, fill)
	}
	static fillRooms(n, sm, lg, m){
		for(i in 1..n)randomRoom(sm, lg, m)
	}
	static randomRoom(sm, lg, m){
		if(sm%2==1 || lg%2==1){
			TIC.trace("WARNING: room sizes should be even")
		}
		var w = __rnd.int(sm/2, lg/2) * 2
		var h = __rnd.int(sm/2, lg/2) * 2
		var x0 = __rnd.int(2, ((m.w - w)/2).floor) * 2
		var y0 = __rnd.int(2, ((m.h - h)/2).floor) * 2
		digBox(x0, y0, w, h, m)
	}
	static digBox(x0, y0, w, h, m){
		if(x0%2==0 && y0%2==0 && w%2==0 && h%2==0){
			var bCollide = false
			for(x in x0..x0+w){
				for(y in y0..y0+h){
					bCollide = bCollide || !m[x, y]
				}
			}
			if(!bCollide){
				for(x in x0..x0+w){
					for(y in y0..y0+h){
						m[x, y] = false
					}
				}
				return true
			} else {
				return false
			}
		} else {
			return false
		}
	}
	static fillMaze(m){
		while(!checkEvenDug(m)){
			digMaze(__rnd.int((m.w - 1)/2)*2,
										 __rnd.int((m.h - 1)/2)*2, m)
		}
	}
	static checkEvenDug(m){
		var bFilled = true
		for(x in 1..m.w/2){
			for(y in 1..m.h/2){
				bFilled = bFilled && !m[x*2, y*2]
			}
		}
		return bFilled
	}
	static digMaze(x0, y0, m){
		if(x0%2==0 && y0%2==0 && m[x0, y0]){
			var liveCells = [TwoVector.new(x0, y0)]
			m[x0, y0] = false
			while( liveCells.count > 0){
				// pick a live cell
				var activeKey = __rnd.int(liveCells.count)
				var activeCell = liveCells[activeKey]
				// get available directions
				var availableDirs = []
				for(i in 0..3){
					var dir = TwoVector.cardinal[i]
					if(m[activeCell + dir] && m[activeCell + dir * 2]){
						availableDirs.add(dir)
					}
				}
				if(availableDirs.count == 0){
					liveCells.removeAt(activeKey)
				} else {
					var digDir = __rnd.sample(availableDirs)
					m[activeCell + digDir] = false
					m[activeCell + digDir * 2] = false
					liveCells.add(activeCell + digDir * 2)
				}
			}
		} else {
			return false // x and y need to be even and not already dug-out
		}
	}
	static unifyZones(n, m){
		var c = Grid.new(m.w, m.h, -1)
		for(i in 1..m.w-1){
			for(j in 1..m.h-1){
				if(m[i, j]) c[i, j] = 0
			}
		}
		var zones = findContiguous(c, m)
		while(zones > 1){
			var c = Grid.new(m.w, m.h, -1)
			for(i in 1..m.w-1){
				for(j in 1..m.h-1){
					if(m[i, j]) c[i, j] = 0
				}
			}
			zones = findContiguous(c, m)
			var z = zoneLinks(c, m)
			for(i in 1..n){
				digRandomLink(z, m)
			}
		}
	}
	static findContiguous(c, m){
		var contigCounter = 0
		for(x in 1..m.w){
			for(y in 1..m.h){
				if(c[x, y] == -1){
					contigCounter = contigCounter + 1
					var liveFlood = [TwoVector.new(x, y)]
					var whileTest = 0
					while(liveFlood.count > 0){
						whileTest = whileTest + 1
						var liveCell = liveFlood.removeAt(-1)
						c[liveCell] = contigCounter
						for(i in 0..3){
							var dir = TwoVector.cardinal[i]
							if(c[liveCell + dir] == -1){
								liveFlood.add(liveCell + dir)
							}
						}
					}
				}
			}
		}
		return contigCounter
	}
	static zoneLinks(c, m){
		var z = []
		for(x in 1..m.w){
			for(y in 1..m.h){
				if(c[x, y] == 0){
					var nei = findNeighborVals(x, y, c)
					nei.add(0)
					nei = removeDuplicates(nei)
					if(nei.count > 2){
						z.add(TwoVector.new(x, y))
					}
				}
			}
		}
		return z
	}
	static findNeighborVals(x, y, c){
		var n = []
		for(i in 0..3){
			var dir = TwoVector.cardinal[i]
			n.add(c[x + dir.x, y + dir.y])
		}
		return n
	}
	static removeDuplicates(t){
		var s = [t[0]]
		for(i in 1..t.count-1){
			var dup = false
			for(j in 0..s.count-1){
				dup = dup || (t[i] == s[j])
			}
			if(!dup && t[i]!=null) s.add(t[i])
		}
		return s
	}
	static digRandomLink(z, m){
		if(z.count > 0){
			/* var link = __rnd.sample(z) */
			var link = z.removeAt(__rnd.int(z.count))
			m[link] = false
		}
	}
	static unwindMaze(m){
		var dead = []
		// find dead ends
		for(x in 2..(m.w-1)){
			for(y in 2..(m.h-1)){
				if(countWalls(x, y, m) == 3){
					dead.add(TwoVector.new(x, y))
				}
			}
		}
		while(dead.count > 0){
			var deadKey = __rnd.int(dead.count)
			var deadCell = dead[deadKey]
			if(!m[deadCell]){
				m[deadCell] = true
				for(i in 0..3){
					var dir = TwoVector.cardinal[i]
					if(countWalls(deadCell + dir, m) == 3){
						dead.add(deadCell + dir)
					}
				}
			}
			dead.removeAt(deadKey)
		}
	}
	static countWalls(x, y, m){
		var walls = 0
		var nei = findNeighborVals(x, y, m)
		for(i in nei){
			if(i) walls = walls + 1
		}
		return walls
	}
	static countWalls(pos, m){countWalls(pos.x, pos.y, m)}
}

// </CODE5>

// <CODE6>
// Game Consts

var LEVEL_WIDTH=35//59
var LEVEL_HEIGHT=35//59

// Renderer Objects
//var PLAYER_RENDER=Renderer.new("@",1,9)
//var GHOST_RENDER=Renderer.new("&",2,11)

// Tile Objects
//var EMPTY=

// </CODE6>

// <CODE7>

// Math / Utility

import "random" for Random
var RANDOM_LEVEL_GEN = Random.new()
var RANDOM_MONSTER_AI = Random.new()
var RANDOM_SEED_GEN = Random.new()

class Math{
	static circle(x0, y0, r){
		var cir = []
		var x = r - 1
		var y = 0
		var dx = 1
		var dy = 1
		var er = dx - (r * 2)
		while(x >= y){
			// add cell to each octant
			for(a in [-1, 1]){
				for(b in [-1, 1]){
					for(c in [-1, 1]){
						cir.add([x0 + b*(0.5*((1+a)*x+(1-a)*y)),
															y0 + c*(0.5*((1+a)*y+(1-a)*x))])
					}
				}
			}
			// go to next place
			if(er <= 0){
				y = y + 1
				er = er + dy
				dy = dy + 2
			}
			if(er > 0){
				x = x - 1
				dx = dx + 2
				er = er + dx - r*2
			}
		}
		return cir
	}
}

class Debug{
	static eagleEye{ false }
}

// </CODE7>

// <TILES>
// 001:efffffffff222222f8888888f8222222f8fffffff8ff0ffff8ff0ffff8ff0fff
// 002:fffffeee2222ffee88880fee22280feefff80fff0ff80f0f0ff80f0f0ff80f0f
// 003:efffffffff222222f8888888f8222222f8fffffff8fffffff8ff0ffff8ff0fff
// 004:fffffeee2222ffee88880fee22280feefff80ffffff80f0f0ff80f0f0ff80f0f
// 017:f8fffffff8888888f888f888f8888ffff8888888f2222222ff000fffefffffef
// 018:fff800ff88880ffef8880fee88880fee88880fee2222ffee000ffeeeffffeeee
// 019:f8fffffff8888888f888f888f8888ffff8888888f2222222ff000fffefffffef
// 020:fff800ff88880ffef8880fee88880fee88880fee2222ffee000ffeeeffffeeee
// </TILES>

// <WAVES>
// 000:00000000ffffffff00000000ffffffff
// 001:0123456789abcdeffedcba9876543210
// 002:0123456789abcdef0123456789abcdef
// </WAVES>

// <SFX>
// 000:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000304000000000
// </SFX>

// <PALETTE>
// 000:140c1c44243430346d4e4a4e854c30346524d04648757161597dced27d2c8595a16daa2cd2aa996dc2cadad45edeeed6
// </PALETTE>

