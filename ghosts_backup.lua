-- title:  Tic-RL
-- author: Quinten Konyn
-- desc:   My Tic-80 RL Engine :~)
-- script: lua

-- NOTE: Uses banks.

-- TODO
-- refactoring
-- add ghosts

--game vars
game={turn=-1,update=true}

function init()
	world_init()
end

init()
function TIC()
	if game.update==true then
		world_update()
		game.turn=game.turn+1
		game.update=false
	end
		draw()
	game.update=getinput()
end

-- Display Library

--display settings:
--odd vals for w and h are buggy
--display={w=31,h=17,px=7}
mainDisp={w=17,h=17,px=7,offs={},buf=2}
mainDisp.offs.x=
	(240-mainDisp.w*mainDisp.px)//2
mainDisp.offs.y=
	(136-mainDisp.h*mainDisp.px)//2

miniDisp={w=35,h=35,px=1,offs={},buf=2}
miniDisp.offs.x=mainDisp.offs.x+
																mainDisp.w*mainDisp.px+
																mainDisp.buf+5
miniDisp.offs.y=mainDisp.offs.y

miniEagleDisp={px=1,offs={},buf=2}
miniEagleDisp.offs.x=mainDisp.offs.x
miniEagleDisp.offs.y=mainDisp.offs.y
miniEagleDisp.w=(mainDisp.w*mainDisp.px+
	2*(mainDisp.buf-miniEagleDisp.buf))//
	miniEagleDisp.px
miniEagleDisp.h=(mainDisp.h*mainDisp.px+
	2*(mainDisp.buf-miniEagleDisp.buf))//
	miniEagleDisp.px

miniBigDisp={px=3,buf=3,offs={}}
miniBigDisp.offs.x=mainDisp.offs.x
																			-mainDisp.buf
																			+miniBigDisp.buf
miniBigDisp.offs.y=mainDisp.offs.y
																			-mainDisp.buf
																			+miniBigDisp.buf
miniBigDisp.w=(mainDisp.w*mainDisp.px+
	2*(mainDisp.buf-miniBigDisp.buf))//
	miniBigDisp.px
miniBigDisp.h=(mainDisp.h*mainDisp.px+
	2*(mainDisp.buf-miniBigDisp.buf))//
	miniBigDisp.px

--color palette
--[[pal
dim: dim lighting
	fg: default foreground
 bg: default background
edg: border
	rm: remembered
--]]
pal={fg=9,bg=15,edg=0,rm=1}
lightpal={
{ 0},--Black
{ 1, 1, 0},--Dark Red
{ 2, 2, 0},--Dark Blue
{ 3, 2, 0},--Dark Gray
{ 4, 1, 0},--Brown
{ 5, 0},--Dark Green
{ 6, 4, 0},--Red
{ 7, 3, 2, 0},--{7,3,2,0},--Light Gray
{ 8, 2, 0},--Light Blue
{ 9, 9, 4, 1, 0},--Orange
{10, 7, 3, 2, 0},--{10,7,3,2,0},--Blue/Gray --3,2,0
{11, 5, 4, 1, 0},--Light Green
{12, 4, 1, 0},--Peach
{13, 8, 2, 0},--Cyan
{14, 9, 4, 1, 0},--Yellow
{15, 14, 9, 4, 1, 0}--{15,10,7,3,2,0}--White
}

function draw()
	cls(0)
	if ui.main.v==2 then
		drawmini(level,miniBigDisp)
		drawborder(miniBigDisp,1)
	elseif ui.main.v==3 then
		drawmini(level,miniEagleDisp)
		drawborder(miniEagleDisp,1)
	elseif ui.main.v==1 then
		drawmap(level,mainDisp)
		drawborder(mainDisp,1)
	end
	drawmini(level,miniDisp)
	drawborder(miniDisp,1)
	--print('turns: '..game.turn,0,0,2)
end

function drawmini(l,d)
	local t,c,x0,y0,dim,ih,jh
	local ph={}
	local offs=displayoff(l,d)
	x0=d.offs.x
	y0=d.offs.y
	dim=d.px
	-- Draw Map
 for i=1,d.w do
	for j=1,d.h do
		ih=i+offs.x
		jh=j+offs.y
		t=getTile(l,ih,jh)
		if t and(t.se or ui.seeAll)then
			if t.so then
				c=1 --walls always purple
			elseif t.bg==0 then
					c=3
			else
					c=t.bg --floor grey if unseen
			end
			rect(i*dim+x0,j*dim+y0,dim,dim,c)
			--pix(i+x0,j+y0,c)
		end
	end
	end
	-- Draw Mobs
	for i=1,#mobs do
	local m=mobs[i]
	-- check location is valid:
	if m.x and m.y then
			ph.x=m.x-offs.x
			ph.y=m.y-offs.y
	-- check in bounds of display:
	if ph.x > 0 and ph.x < d.w and
				ph.y > 0 and ph.y < d.h and
	-- check seen before:
				(m.rend.se or ui.seeAll) then
	 rect(ph.x*dim+dim//2+x0,
							ph.y*dim+dim//2+y0,
							dim//2,dim//2,5)
	end
	end
	end
end

function displayoff(l,d)
	local o={x=0,y=0}
	local p=player
	--simple offset:
	o.x=p.x-d.w//2-1
	o.y=p.y-d.h//2-1
	--boundaries:
	if p.y*2<d.h then --top
		o.y=0
	elseif p.y>l.h-d.h//2 then --bottom
		o.y=l.h-d.h
	end
	if p.x*2<d.w then --left
		o.x=0
	elseif p.x>l.w-d.w//2 then --right
		o.x=l.w-d.w
	end
	--too small:
	if d.h>=l.h then --too short
		o.y=(l.h-d.h)//2
	end
	if d.h>=l.h then --too thin
		o.x=(l.w-d.w)//2
	end
	return o
end

function drawborder(d,col)
	local buff=d.buf
	local x0,y0,x1,y1
	x0=d.offs.x-buff
	y0=d.offs.y-buff
	x1=d.w*d.px+x0-1+2*buff
	y1=d.h*d.px+y0-1+2*buff
	line(x0,y0,x0,y1,col)
	line(x0,y0,x1,y0,col)
	line(x1,y0,x1,y1,col)
	line(x0,y1,x1,y1,col)
end

function drawmap(l,d)
	local offs=displayoff(l,d)
	local i,j,t,col
	-- Draw Map
	for id=1,d.w do
	for jd=1,d.h do
		i=id+offs.x
		j=jd+offs.y
		t=getTile(l,i,j)
		sspr(d,t,id-1,jd-1)
	end
	end
	--[[Draw Mobs
	for i=1,#mobs do
		local mob=mobs[i]
		t=mob.rend
		local id=mob.x-offs.x
		local jd=mob.y-offs.y
		sspr(d,t,id-1,jd-1)
	end
	--]]
end

function sspr(d,t,x,y)
	local offsy,offsx,rx,ry,px,py
	local fg,bg,dimidx,palLen,m,ch
	--calculations for centering tile right
--	offsy=(136-d.h*d.px)//2
--	offsx=(240-d.w*d.px)//2
	rx=d.px*x+d.offs.x
	ry=d.px*y+d.offs.y
	px=d.px*(x+0.5)+d.offs.x
	py=d.px*(y+0.5)+d.offs.y

	if not t then t=VOID end
	--if a mob on tile, draw that instead
	if t.mob then
		m=t.mob.rend
		m.vi=t.vi
		m.se=t.se
	end

	--determine the display colors
	fg,bg=illumCol(t)
	ch=t.ch
	if m then
		fg=illumCol(m)
		ch=m.ch
	end

	--draw background tile
	rect(rx,ry,d.px,d.px,bg)
	--draw foreground tile
	printc(ch,px,py,fg)
end
--[[pal
dim: dim lighting
	fg: default foreground
 bg: default background 1
edg: border
--]]

--Prints text where x is the center of text.
function printc(s,x,y,c)
    local w=print(s,0,-8)
    print(s,x-(w/2)+1,y-2,c or 15)
				--y offset is 2 not 3 b/c 'j'
end

-- Map Library

--map information:
level={data={},w=LEVEL_WIDTH,
															h=LEVEL_HEIGHT,r={}}
--setDefault(level.data, EMPTY)

--constants for tiles
--[[
ch: string representation
c1: foreground color
c2: background color
so: solid (bool)
op: opaque (bool)
id: unique tile type identifier
vi: currently visible
se: seen previously
--]]
--3 and 10
EMPTY={ch='`',vi=2,c1=9}
WALL={ch='#',so=true,op=true,vi=2}
VOID={ch='',c1=1,c2=0,vi=0}

function world_init()
	addEmpty(level)
	--addWalls(level)
	--addRandom(level)
	local sh=genDungeon(15,level.w)
	addFromProc(level,sh)
	newmobs(mobs,GHOST_TEMPLATE,100)
	placemobs(level,mobs)
	world_update()
end

function world_update()
	rayTrace(level,player)
	updateVisability(level)
end

function randomFree(l)
	local i,j,t
	for tries=1,5000 do
		i=m.random(l.w)
		j=m.random(l.h)
		t=getTile(l,i,j)
		if not checkSolid(t) then
			return i,j
		end
	end
	return false
end

function checkSolid(t)
 return (not t) or t.so or t.mob
end

function addEmpty(l)
	--fills with empty tiles
	for i=1,l.w do
	for j=1,l.h do
		setTile(l,i,j,EMPTY)
	end
	end
end

function addWalls(l)
	--adds boundary walls
	for i=1,l.w do
		j=1
		setTile(l,i,j,WALL)
		j=l.h
		setTile(l,i,j,WALL)
	end
	for j=2,l.h-1 do
		i=1
		setTile(l,i,j,WALL)
		i=l.w
		setTile(l,i,j,WALL)
	end
end

function addRandom(l)
 for i=1,l.w do
	for j=1,l.h do
		if m.random(10)==10 then
			setTile(l,i,j,WALL)
		end
	end
	end
end

function addFromProc(l,pr)
	for i=1,l.w do
	for j=1,l.h do
		if pr.d[idx(i,j,pr.w)] then
			setTile(l,i,j,WALL)
		end
	end
	end
end

function addMaze(l)
	local spots={}
end

function getIDX(l,x,y)
	return x+(y-1)*l.w
end

function inBounds(l,x,y)
	local xb,yb
	xb=x>0 and x<l.w+1
	yb=y>0 and y<l.h+1
	return xb and yb
end

function getTile(l,x,y)
	if inBounds(l,x,y) then
		return l.data[getIDX(l,x,y)]
	else
		return nil
	end
end

function setTile(l,x,y,v)
	if inBounds(l,x,y) then
		local w=shallowCopy(v)
		l.data[getIDX(l,x,y)]=w
	end
end

function tweakTile(l,x,y,idx,v)
	if inBounds(l,x,y) then
			l.data[getIDX(l,x,y)][idx]=v
	end
end

function updateVisability(l)
	local IDX,vis,distsq
	--local idx
	local p=player
	for i=1,l.w do
	for j=1,l.h do
		--distance-limited visibility
		dist=m.sqrt((i-p.x)^2+(j-p.y)^2)
		vis=m.max(dist-p.vis+2*p.dim,p.dim)//p.dim
		--obstruction-limited visibility
		--TODO
		if not l.r.locVis[idx(i,j,l.w)] then
			vis=m.max(999-p.vis+2*p.dim,p.dim)
		end
		tweakTile(l,i,j,'vi',vis)
		local m=getTile(l,i,j).mob
		if m then m.rend.vis=vis end
		--make this function next time:
		rememberVisible(l,i,j)
		--use color logic from SSPR
		--make a function for that color
		--logic so that it stays in sync
	end
	end
end

function rememberVisible(l,i,j)
	local t,fg,bg
	t=getTile(l,i,j)
	t.fg,t.bg=illumCol(t)
	if not(t.fg==t.bg) then
		tweakTile(l,i,j,'se',true)
	end
	if t.mob then
		t.mob.rend.se=t.se
		t.mob.rend.fg=illumCol(t)
	end
end

function illumCol(t)
	local palLen,fg,bg,dimidx
	if t then
		--get initial colors
		fg=t.c1 or pal.fg
		bg=t.c2 or pal.bg
		--get color according to lighting
		--foreground
		palLen=#(lightpal[fg+1])
		dimidx=m.min(t.vi,palLen)
		fg=lightpal[fg+1][dimidx]
		--background
		palLen=#(lightpal[bg+1])
		dimidx=m.min(t.vi,palLen)
		bg=lightpal[bg+1][dimidx]
		--if seen previously, show dimly
		if fg==bg then
		if t.se or ui.seeAll then
			fg=pal.rm
		end end
	--]]
	end
	return fg, bg
end



--After this, procedural generation code

function newLevel(w,fill)
  --creates new level object
  --square, with width w
  --filled with either true or false
  local l={}
  l.w=w l.d={}
  for y=1, l.w do
    for x=1, l.w do
      l.d[idx(x,y,l.w)]=fill
    end
  end
  return l
end

function addBoundaryWalls(l)
  --adds boundary walls to an existing level
  for x=1,l.w do
    l.d[idx(x,1,l.w)]=true
    l.d[idx(x,l.w,l.w)]=true
  end
  for y=2,l.w-1 do
    l.d[idx(1,y,l.w)]=true
    l.d[idx(l.w,y,l.w)]=true
  end
end

-- global direction constants:
FOURDIR = { {x=0,y=1}, {x=0,y=-1}, {x=1,y=0}, {x=-1,y=0} }

function digMaze(x0,y0,l)
  -- digs a maze starting at point x,y
  -- enforce an even starting point for dungeon consistency
  -- and that we're not starting in an already dug-out space:
  if x0%2==0 and y0%2==0 and l.d[idx(x0, y0, l.w)] then
    -- start with one live cell
    liveCells = {{x=x0,y=y0}}
    -- dig out first cell
    l.d[idx(x0, y0, l.w)] = false
    repeat
    --while #liveCells > 0 do
      -- pick a live cell
      activeKey = math.random(#liveCells)
      activeCell = liveCells[activeKey]
      -- go through each surrounding cell, checking which are available
      availableDirs = {}
      for k,dir in ipairs(FOURDIR) do
        if l.d[idx(activeCell.x+dir.x, activeCell.y+dir.y, l.w)] and l.d[idx(activeCell.x+2*dir.x, activeCell.y+2*dir.y, l.w)] then
          -- if the potential cell has not been dug yet, add to list
          availableDirs[#availableDirs+1]=dir
        end
      end
      if #availableDirs == 0 then
        -- if none are available, remove from live list
        table.remove(liveCells,activeKey)
      else
        -- otherwise, dig through to a random available cell
        digDir = availableDirs[math.random(#availableDirs)] -- TODO: make random
        l.d[idx(activeCell.x+digDir.x, activeCell.y+digDir.y, l.w)] = false
        l.d[idx(activeCell.x+2*digDir.x, activeCell.y+2*digDir.y, l.w)] = false
        -- add the new cell to the live cell list
        liveCells[#liveCells+1] = {x=activeCell.x+2*digDir.x, y=activeCell.y+2*digDir.y}
      end
    --end
    until #liveCells == 0
    return true
  else
    --print('digMaze failed: x and y need to be even and not start in already dug-out space')
    return false
  end
end

function digBox(x0,y0,w,h,l)
  -- digs out a rectangular box
  -- enforce that the box will fit in the grid properly:
  if x0%2==0 and y0%2==0 and w%2==0 and h%2==0 then
  -- enforce that box is within bounds and is not colliding:
    bCollide=false
    for x=x0,x0+w do for y=y0,y0+h do
      bCollide = bCollide or not l.d[idx(x, y, l.w)]
    end end
    if not bCollide then
    --dig the box:
      for x=x0,x0+w do for y=y0,y0+h do
        l.d[idx(x, y, l.w)] = false
      end end
      return true
    else
      --print('digMaze failed: box collided')
      return false
    end
  else
    --print('digMaze failed: x and y need to be even and w and h need to be even')
    return false
  end
end

function randomRoom(smallest,largest,l)
  -- dig out a random room
  -- keep smallest & largest even
  if smallest%2==1 or largest%2==1 then
  trace('warning: room sizes should be even')
  end
  w = math.random(smallest/2,largest/2)*2
  h = math.random(smallest/2,largest/2)*2
  x0 = math.random(2,(l.w-w)//2)*2
  y0 = math.random(2,(l.w-h)//2)*2
  digBox(x0,y0,w,h,l)
end

function checkEvenDug(l)
  -- returns true if all cells with an even x and y are dug out
  local bFilled = true
  for x=2,l.w,2 do for y=2,l.w,2 do
    bFilled = bFilled and not l.d[idx(x,y,l.w)]
  end end
  return bFilled
end

function fillMaze(l)
  -- randomly adds mazes using digMaze until everything's filled up
  repeat
    digMaze(math.random((l.w-1)/2)*2,math.random((l.w-1)/2)*2,l)
  until checkEvenDug(l)
end

function findContiguous(l)
  -- numbers each dug-out tile according to contiguous-ness
  -- does not count diagonals as contiguous!
  -- returns the number of zones
  local i,x,y,bDone,liveFlood
  -- initialize a new array from l.d
  l.cont = {}
  for y=1, l.w do for x=1, l.w do
    i = idx(x,y,l.w)
    if l.d[i] then
      l.cont[i]=0 -- 0 signifies a wall
    else
      l.cont[i]=-1 -- -1 signifies unchecked
    end
  end end
  -- go through l.d until you find a -1
  contigCounter = 0
  for x=1,l.w do for y=1,l.w do
    if l.cont[idx(x,y,l.w)]==-1 then
      -- assign the cell a counter number
      contigCounter=contigCounter+1
      -- flood fill from the cell and set all in fill to that number
      liveFlood = {{x=x,y=y}}
      repeat
        liveCell = table.remove(liveFlood) --pop
        l.cont[idx(liveCell.x,liveCell.y,l.w)]=contigCounter
        for k,dir in ipairs(FOURDIR) do
          if l.cont[idx(liveCell.x+dir.x,liveCell.y+dir.y,l.w)]==-1 then
            liveFlood[#liveFlood+1]={x=liveCell.x+dir.x,y=liveCell.y+dir.y}
          end
        end
      until #liveFlood==0
    end
  end end
  return contigCounter
end

function findNeighborVals(x,y,a,w)
  -- return a list of values of each cardinal neighbor
  local n = {}
  for k,dir in ipairs(FOURDIR) do
    n[#n+1] = a[idx(x+dir.x,y+dir.y,w)]
  end
  return n
end

function removeDuplicates(t)
  -- returns a list with (scalar) duplicates removed
  local s, dup
  s = {}
  for k,v in ipairs(t) do
    dup = false
    for j,w in ipairs(s) do
      dup = dup or (v == w)
    end
    if not dup then
      s[#s+1] = v
    end
  end
  return s
end

function zoneLinks(l)
  -- make a list of cells that go between distinct zones
  local nei,links
  l.links = {}
  for x=1,l.w do for y=1,l.w do
    if l.cont[idx(x,y,l.w)] == 0 then
      nei = findNeighborVals(x,y,l.cont,l.w)
      nei[5] = 0 -- ensure we're consistently counting 0
      nei = removeDuplicates(nei)
      if #nei > 2 then
        l.links[#l.links+1] = {x=x,y=y}
      end
    end
  end end
end

function digRandomLink(l)
  -- digs a random zone link from l.links
  if #l.links > 0 then
    local link = l.links[math.random(#l.links)]
    l.d[idx(link.x,link.y,l.w)] = false
  end
end

function unifyZones(n,l)
  -- add connections until all cells are contiguous
  -- adds n at a time- set n=1 for zero redundancy
  local zones = findContiguous(l)
  while zones > 1 do
    zones = findContiguous(l)
    zoneLinks(l)
    for i=1,n do
      digRandomLink(l)
    end
  end
end

function countWalls(x,y,l)
  -- count neighbors that are walls
  local walls
  nei = findNeighborVals(x,y,l.d,l.w)
  walls = 0
  for k,v in ipairs(nei) do
    if v then walls=walls+1 end
  end
  return walls
end

function unwindMaze(l)
  -- creates sparseness by retracting dead-ends
  -- later, add an option to do this only partially
  local dead, nei, walls
  dead={}
  -- find dead-ends
  for x=2,l.w-1 do for y=2,l.w-1 do
    -- if three neighbors are a wall, it's a dead-end
    if countWalls(x,y,l) == 3 then
      dead[#dead+1] = {x=x,y=y}
    end
  end end
  -- while there are still dead ends,
  while #dead > 0 do
    -- pick a random dead-end
    deadKey = math.random(#dead)
    deadCell = dead[deadKey]
    -- if it's already filled in, skip it
    if not l.d[idx(deadCell.x,deadCell.y,l.w)] then
      -- fill it in
      l.d[idx(deadCell.x,deadCell.y,l.w)] = true
      -- check if neighboring dug-out cells became dead-ends
      for k,dir in ipairs(FOURDIR) do
        if countWalls(deadCell.x+dir.x,deadCell.y+dir.y,l) == 3 then
          dead[#dead+1] = {x=deadCell.x+dir.x,y=deadCell.y+dir.y}
        end
      end
    end
    -- remove it from dead list
    table.remove(dead,deadKey)
  end
end

function fillRooms(n,sm,lg,l)
  for i=1,n do
    randomRoom(sm,lg,l)
  end
end

function countValue(t,v)
  -- returns the number of entries in the table that equal v
  local n=0
  for i=1,#t do
    if t[i]==v then
      n=n+1
    end
  end
  return n
end

function nPassCopy(t,n)
  local newt = {} -- haha puns
  -- copies a table to a depth of n
  if n>0 and type(t)=='table' then
    for k,v in pairs(t) do
      newt[k] = nPassCopy(v,n-1)
    end
    return newt
  else
    return t
  end
end

function genDungeon(n,w)
  -- make a level
		local p=player
  local genLevel=newLevel(w,true)
  local activeLevel
		-- dig out starting room around player
		digBox(p.x-1,p.y-1,2,2,genLevel)
  -- generate room placement
  fillRooms(10,6,12,genLevel)
  fillRooms(100,4,6,genLevel)
  -- try a bunch of different hallway setups
  local hallwayLevels={}
  local hallwayLengths={}
  for i=1,n do
    activeLevel = nPassCopy(genLevel,2)
    fillMaze(activeLevel)
    unifyZones(10,activeLevel)
    unwindMaze(activeLevel)
    hallwayLevels[i] = activeLevel
    hallwayLengths[i] = countValue(activeLevel.d,false)
  end
  local longestL = math.max(table.unpack(hallwayLengths))
  local shortestL = math.min(table.unpack(hallwayLengths))
  local shortest, longest
  for i=1,n do
    if hallwayLengths[i] == longestL then
      longest = hallwayLevels[i]
    end
    if hallwayLengths[i] == shortestL then
      shortest = hallwayLevels[i]
    end
  end
  return shortest, longest
end

-- Mobs Library

--constants for mobs
PLAYER_RENDER={ch='@',vi=1,c1=9}
GHOST_RENDER={ch='&',vi=2,c1=11}

--player:
player={x=LEVEL_WIDTH//2,
								y=LEVEL_HEIGHT//2,vis=3,dim=1,
								rend=PLAYER_RENDER}
--mob templates:
GHOST_TEMPLATE={rend=GHOST_RENDER}

mobs={player}

function newmobs(ms,temp,n)
	for i=1,n do
		ms[#ms+1]=shallowCopy(temp)
	end
end

function placemobs(l,ms)
	local m
	for i=1,#ms do
		m=ms[i]
		if not (m.x and m.y) then
			m.x,m.y=randomFree(l)

			if not m.x then
				trace("monster overflow")
				return false
			end

		end
		tweakTile(l,m.x,m.y,"mob",m)
	end
end

function movemob(l,m,dx,dy)
	--remove from old tile
	tweakTile(l,m.x,m.y,"mob",nil)
	--modify mob position
	m.x=m.x+dx
	m.y=m.y+dy
	--establish in new tile
	tweakTile(l,m.x,m.y,"mob",m)
end

function trymove(d)
	local solid
	local p=player
	--check for collisions
	local t=getTile(level,p.x+d.x,p.y+d.y)
	solid=checkSolid(t)
	--move if free to
	if not solid then
		--p.x=p.x+d.x
		--p.y=p.y+d.y
		movemob(level,p,d.x,d.y)
		return true
		--game.update=true
	end
	return false
end

--UI

ui={main={v=1,opt={}},r1=1}
ui.main.opt={"game","big","eagle"}
ui.seeAll=false

function getinput()
	local hold=30
	local period=5
	--up
	if btnp(0,hold,period)then
		return trymove({x=0,y=-1})
	end
	--down
	if btnp(1,hold,period)then
		return trymove({x=0,y=1})
	end
	--left
	if btnp(2,hold,period)then
		return trymove({x=-1,y=0})
	end
	--right
	if btnp(3,hold,period)then
		return trymove({x=1,y=0})
	end
	--z
	if btnp(4,hold,period)then
  return setTile(level,player.x,player.y,WALL)
	end
	--x
	if btnp(5,hold,period)then
	end
	--Alphabet:
	if keyp(13,hold,period)then
		if key(64) then
		--M
			ui.seeAll=not ui.seeAll
			return false
		else
		--m
			return cycleMenu(ui,"main")
		end
	end
	--
	return false
end

function cycleMenu(u,m)
	u[m].v=u[m].v%(#u[m].opt)+1
	return false
end

-- Raytracing
-- Not Yet Implemented!

--[[
function newLevel(w,fill)
  --creates new level object
  --square, with width w
  --filled with either true or false
  local l={}
  l.w=w l.d={}
  for y=1, l.w do
    for x=1, l.w do
      l.d[idx(x,y,l.w)]=fill
    end
  end
  return l
end
--]]

function newLocal(lv,p)
 local l={}
	l.w=lv.w l.d={}
	for y=1,lv.h do
		for x=1,lv.w do
			local t=getTile(lv,x,y)
			if t then
				l.d[idx(x,y,l.w)]=t.op
			else
				l.d[idx(x,y,l.w)]=true
			end
	end end
	return l
end

function densenSpatialTable(t,w)
  local tt={}
  for y=1, w do
  for x=1, w do
    for xx=(x-1)*cdens+1,x*cdens do
    for yy=(y-1)*cdens+1,y*cdens do
      tt[idx(xx,yy,w*cdens)]=t[idx(x,y,w)]
    end
    end
  end
  end
  return tt
end

function compressSpatialTable(tt,w,mode)
  local btrue
  local t={}
  mode = mode or 'or'
  if mode=='center' and cdens%2==0 then --center only works for odd
    mode = 'or'
  end
  if mode=='or' then
    -- does or-ing; w is for the compressed width
    for y=1, w do
    for x=1, w do
      btrue=false
    for xx=(x-1)*cdens+1,x*cdens do
    for yy=(y-1)*cdens+1,y*cdens do
        btrue = btrue or tt[idx(xx,yy,w*cdens)]
        --tt[idx(xx,yy,w*2)]=t[idx(x,y,w)]
      end
      end
      t[idx(x,y,w)]=btrue
    end
    end
  elseif mode=='and' then
    -- does or-ing; w is for the compressed width
    for y=1, w do
    for x=1, w do
      btrue=true
      for xx=(x-1)*cdens+1,x*cdens do
      for yy=(y-1)*cdens+1,y*cdens do
        btrue = btrue and tt[idx(xx,yy,w*cdens)]
        --tt[idx(xx,yy,w*2)]=t[idx(x,y,w)]
      end
      end
      t[idx(x,y,w)]=btrue
    end
    end
  elseif mode=='center' then
    -- center is required to be seen for visibility
    for y=1, w do
    for x=1, w do
      t[idx(x,y,w)]=tt[idx(x*cdens-1,y*cdens-1,w*cdens)]
    end
    end
  end
  return t
end

function densenPointTable(t)
  local tt={}
  local x,y
  for k,v in ipairs(t) do
    x=v[1] y=v[2]
    for xx=(x-1)*cdens+1,x*cdens do
    for yy=(y-1)*cdens+1,y*cdens do
      tt[#tt+1]={xx,yy}
    end
    end
  end
  return tt
end

function updateDenseOpaque(l)
  --[[creates an array l.dd that matches l.d, but is cdens times
      as dense. Now with "diamond" walls!]]
  local xx, yy, xc, yc, wc
  l.dd={}
  for y=1, l.w do
  for x=1, l.w do
    if cdens%2==1 then --fancy mode (only for odd density)
      if l.d[idx(x,y,l.w)] then
        --center coords
        wc=(cdens-1)/2 --'width' (more like radius) from center
        xc=x*cdens-wc
        yc=y*cdens-wc
        --diamonds:
        for xx=0,wc do for yy=-wc+xx,0 do
          l.dd[idx(xc+xx,yc+yy,l.w*cdens)]=true --northeast
        end end
        for xx=-wc,0 do for yy=-wc-xx,0 do
          l.dd[idx(xc+xx,yc+yy,l.w*cdens)]=true --northwest
        end end
        for xx=0,wc do for yy=0,wc-xx do
          l.dd[idx(xc+xx,yc+yy,l.w*cdens)]=true --southeast
        end end
        for xx=-wc,0 do for yy=0,wc+xx do
          l.dd[idx(xc+xx,yc+yy,l.w*cdens)]=true --southwest
        end end
        --bevels
        if l.d[idx(x,y-1,l.w)] then --if north opaque
          for xx=-wc,0 do for yy=0,wc+xx do
            l.dd[idx(xc+wc+xx,yc-wc+yy,l.w*cdens)]=true --northeast
          end end
          for xx=0,wc do for yy=0,wc-xx do
            l.dd[idx(xc-wc+xx,yc-wc+yy,l.w*cdens)]=true --northwest
          end end
        end
        if l.d[idx(x,y+1,l.w)] then --if south opaque
          for xx=-wc,0 do for yy=-wc-xx,0 do
            l.dd[idx(xc+wc+xx,yc+wc+yy,l.w*cdens)]=true --southeast
          end end
          for xx=0,wc do for yy=-wc+xx,0 do
            l.dd[idx(xc-wc+xx,yc+wc+yy,l.w*cdens)]=true --southwest
          end end
        end
        if l.d[idx(x+1,y,l.w)] then --if east opaque
          for xx=-wc,0 do for yy=0,wc+xx do
            l.dd[idx(xc+wc+xx,yc-wc+yy,l.w*cdens)]=true --northeast
          end end
          for xx=-wc,0 do for yy=-wc-xx,0 do
            l.dd[idx(xc+wc+xx,yc+wc+yy,l.w*cdens)]=true --southeast
          end end
        end
        if l.d[idx(x-1,y,l.w)] then --if west opaque
          for xx=0,wc do for yy=0,wc-xx do
            l.dd[idx(xc-wc+xx,yc-wc+yy,l.w*cdens)]=true --northwest
          end end
          for xx=0,wc do for yy=-wc+xx,0 do
            l.dd[idx(xc-wc+xx,yc+wc+yy,l.w*cdens)]=true --southwest
          end end
        end
      end
    else --old mode
      for xx=(x-1)*cdens+1,x*cdens do
      for yy=(y-1)*cdens+1,y*cdens do
        l.dd[idx(xx,yy,l.w*cdens)]=l.d[idx(x,y,l.w)]
      end
      end
    end
  end
  end
  --l.dd = densenSpatialTable(l.d,l.w)
end

--[[
function bresenham(x1, y1, x2, y2)
  --unused; logic used in ray()
  local dx,dy,ix,iy,er
  dx=x2-x1
  ix=dx>0 and 1 or -1
  dx=2*math.abs(dx)
  dy=y2-y1
  iy=dy>0 and 1 or -1
  dy=2*math.abs(dy)
  plot(x1,y1)
  if dx>=dy then
    er=dy-dx/2 --error
    while x1~=x2 do
      if(er>0)or((er==0)and(ix>0))then
        er=er-dx
        y1=y1+iy
      end
      er=er+dy
      x1=x1+ix
      --plot(x1,y1)
    end
  else
    er=dx-dy/2
    while y1~=y2 do
      if(er>0)or((er==0)and(iy>0))then
        er=er-dy
        x1=x1+ix
      end
      er=er+dx
      y1=y1+iy
      --plot(x1,y1)
    end
  end
end
--]]

function ray(l, x1, y1, x2, y2)
  local dx,dy,ix,iy,er,power
  dx=x2-x1
  ix=dx>0 and 1 or -1
  dx=2*math.abs(dx)
  dy=y2-y1
  iy=dy>0 and 1 or -1
  dy=2*math.abs(dy)
  power=2 --light dies after going through 1 opaques
  --plot(x1,y1)
  l.dvis[idx(x1,y1,l.w*cdens)]=true
  if dx>=dy then
    er=dy-dx/2 --error
    while x1~=x2 and power>1 do
      if(er>0)or((er==0)and(ix>0))then
        er=er-dx
        y1=y1+iy
      end
      er=er+dy
      x1=x1+ix
      --plot(x1,y1)
      l.dvis[idx(x1,y1,l.w*cdens)]=true
      if l.dd[idx(x1,y1,l.w*cdens)] then
        power=power-1
      end
    end
  else
    er=dx-dy/2
    while y1~=y2 and power>1 do
      if(er>0)or((er==0)and(iy>0))then
        er=er-dy
        x1=x1+ix
      end
      er=er+dx
      y1=y1+iy
      --plot(x1,y1)
      l.dvis[idx(x1,y1,l.w*cdens)]=true
      if l.dd[idx(x1,y1,l.w*cdens)] then
        power=power-1
      end
    end
  end
end

function denseRayTrace(l,p)
  local boundCirc,x,y,dx,dy
  l.dvis={} --clear out or initialize visibility table
  boundCirc=densenPointTable(circle(p.x,p.y,p.vis*2))
    dx=(cdens-1)/2 dy=(cdens-1)/2
    for k,v in ipairs(boundCirc) do
      x=v[1] y=v[2]
      ray(l,p.x*cdens-dx,p.y*cdens-dy,x,y)
    end
end

--this global should eventually
--be hardcoded:
cdens=3

function rayTrace(lv,p)
		local l
		--create a local map bool repr.
		l=newLocal(lv,p)
  updateDenseOpaque(l)
  denseRayTrace(l,p)
  lv.r.locVis=compressSpatialTable(l.dvis,l.w)
end

-- Game Consts
LEVEL_WIDTH=59
LEVEL_HEIGHT=59

-- Math
m=math
function setDefault(t, d)
	local mt={__index=function()return d end}
	setmetatable(t, mt)
end

function m.round(x)
	return x+0.5-(x+0.5)%1
end

-- Table Logic
function shallowCopy(a)
	local t={}
		for k,v in pairs(a) do
			t[k]=v
		end
	return t
end

-- the following are for raytracer:
function idx(x,y,w)
  --turn x and y into 1D table index
  if x>w or x<1 or y>w or y<1 then
    return 0 --force padding to edges
  else
    return x+w*(y-1)
  end
end

-- TODO I think this is wrong (padding)
function xy_from_idx(i,w)
  --turn 1D table index into x and y
  local x,y
  --x=idx//w --Lua 5.3 supports integer division!!
  x=(i-1)%w+1
  y=math.floor((i-1)/w)+1
  return x,y
end

function circle(x0,y0,r)
  --[[Returns a table of x and y values of a bresenham circle.]]
  local x,y,dx,dy,er,cir
  x=r-1 y=0 dx=1 dy=1 er=dx-(r*2) cir={}
  while x>=y do
    -- add cell to each octant
    for a=-1,1,2 do for b=-1,1,2 do for c=-1,1,2 do
    cir[#cir+1]={x0 + b*(0.5*((1+a)*x+(1-a)*y)), y0 + c*(0.5*((1+a)*y+(1-a)*x))}
    end end end
    -- go to next place
    if er<=0 then
      y=y+1
      er=er+dy
      dy=dy+2
    end
    if er>0 then
      x=x-1
      dx=dx+2
      er=er+dx-r*2
    end
  end
  return cir
end
