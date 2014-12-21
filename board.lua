require('core')
require('sprite')
require('render_manager')
tween = require('tween')

class('Board', Object)

BoardState = {}
BoardState.Idle = 0
BoardState.Move = 1
BoardState.Destroy = 2
BoardState.MoveGems = 3
BoardState.Generate = 4

Animation = {}
Animation.Appear = 1.0
Animation.Move = 0.25
Animation.Destroy = 0.25
Animation.Generate = 0.25
Animation.Fall = 0.25

function copy(obj)
  if type(obj) ~= 'table' then return obj end
  local res = {}
  for k, v in pairs(obj) do res[copy(k)] = copy(v) end
  return res
end

function Board:init(tx, ty)
  self.animations = {}
  self.layer = RenderManager:addLayer('board', 1)
  self.origin = { x = 360, y = 120 }
  self.tiles = {}
  self.tileSize = 35
  self.width = self.tileSize * tx
  self.height = self.tileSize * ty
  self.tx = tx
  self.ty = ty

  self:fill()
  while self:destroyGems(false) == true do
    self:generateGems(false)
  end
  for i=0, self.tx - 1 do
    for j=0, self.ty - 1 do
      local it = self.tiles[i][j]

      --[[
      it.position.x = self.origin.x + i * self.tileSize
      it.position.y = self.origin.y - 1 * self.tileSize
      local pos = {}
      pos.x = self.origin.x + i * self.tileSize
      pos.y = self.origin.y + j * self.tileSize
      local tween1 = tween.new(0.5, it.position, pos, 'linear')
      table.insert(self.animations, tween1)
      ]]--

      local color = copy(it.color)
      it.color.a = 0.0
      local r = math.random() + math.random(1, 2)
      local tween2 = tween.new(r, it.color, color, 'linear')
      table.insert(self.animations, tween2)
    end
  end

  self.state = BoardState.Idle
end

function Board:clear()
  self.layer.sprites = {}
  self.tiles = {}
end

function Board:fill()
  self:clear()
  local seed = math.floor(love.timer.getTime())
  print(seed)
  math.randomseed(seed)
  for i=0, self.tx - 1 do
    self.tiles[i] = {}
    for j=0, self.ty - 1 do
      local r = math.random(1, 5)
      local sprite = Sprite(Sprites.Gems[r])
      sprite.index = { i = i, j = j }
      sprite.item = r
      sprite.position.x = self.origin.x + i * self.tileSize
      sprite.position.y = self.origin.y + j * self.tileSize
      self.layer.sprites[#self.layer.sprites + 1] = sprite
      self.tiles[i][j] = sprite
    end
  end
end

local function isPointInsideRect( x, y, sx, sy, sw, sh )
	local minx = sx
  local miny = sy
  local maxx = sx + sw
  local maxy = sy + sh

  return (x > minx and x < maxx) and (y > miny and y < maxy)
end

function Board:click(x, y)
  if self.state ~= BoardState.Idle then
    return
  end

  if isPointInsideRect(x, y, self.origin.x, self.origin.y, self.width, self.height) then
    local point = { x = x - self.origin.x, y = y - self.origin.y }
    local i = math.floor(point.x / self.tileSize)
    local j = math.floor(point.y / self.tileSize)
    local sprite = self.tiles[i][j]
    self:clickOn(sprite)
  end
end

local function isNeihbor(a, b)
  local idxA = a.index
  local idxB = b.index
  if idxA.i == idxB.i then
    return idxA.j == idxB.j + 1 or idxA.j == idxB.j - 1
  elseif idxA.j == idxB.j then
    return idxA.i == idxB.i + 1 or idxA.i == idxB.i - 1
  end
  return false
end

function Board:clickOn(sprite)
  if self.current == nil then
    self.current = sprite
  elseif isNeihbor(self.current, sprite) then
    self.next = sprite
  else
    self.current = nil
    self.current = sprite
  end
end

function Board:update(dt)
  local hasAnim = self:updateAnimations(dt)
  if hasAnim then
    return
  end

  local prevState = self.state

  if self.state == BoardState.Idle then
    if self.current ~= nil and self.next ~= nil then
      self:moveTile(self.current, self.next, true)
      self.state = BoardState.Move
    end
  elseif self.state == BoardState.Move then
    if self:endMove(true) then
      self.state = BoardState.Destroy
    else
      self:cancelMove(true)
      self.state = BoardState.Idle
    end
  elseif self.state == BoardState.Generate then
    if self:destroyGems(true) then
      self.state = BoardState.Destroy
    else
      self.state = BoardState.Idle
    end
  elseif self.state == BoardState.Destroy then
    self:moveGems(true)
    self.state = BoardState.MoveGems
  elseif self.state == BoardState.MoveGems then
    self:generateGems(true)
    self.state = BoardState.Generate
  end

  if prevState ~= self.state then
    if self.state == BoardState.Idle then
      print('Idle')
    elseif self.state == BoardState.Move then
      print('Move')
    elseif self.state == BoardState.Generate then
      print('Generate')
    elseif self.state == BoardState.MoveGems then
      print('MoveGems')
    elseif self.state == BoardState.Destroy then
      print('Destroy')
    end
  end
end

function Board:updateAnimations(dt)
  local i = 1
  while i <= #self.animations do
    if self.animations[i]:update(dt) then
        table.remove(self.animations, i)
    else
        i = i + 1
    end
  end
  return #self.animations > 0
end

function Board:findEmpty(iCol)
  for j=self.ty-1, 0, -1 do
    local it = self.tiles[iCol][j]
    if it.removed then
      return it
    end
  end
  return nil
end

function Board:findNotEmptyAbove(iCol, jRow)
  for j=jRow, 0, -1 do
    local it = self.tiles[iCol][j]
    if not it.removed then
      return it
    end
  end
  return nil
end

function Board:moveGems(animate)
  for i=0, self.tx-1 do
    while true do
      local empty = self:findEmpty(i)
      if not empty then
        break
      end
      local next = self:findNotEmptyAbove(i, empty.index.j)
      if not next then
        break
      end
      self:moveTile(empty, next, false)
      if animate then
        local tmp = copy(next.position)
        next.position = copy(empty.position)
        local tween1 = tween.new(Animation.Fall, next.position, tmp, 'linear')
        table.insert(self.animations, tween1)
      end
    end
  end
end

function Board:generateGems(animate)
  for i=0, self.tx-1 do
    for j=0, self.ty-1 do
      local it = self.tiles[i][j]
      if it.removed then
        it.removed = nil
        local r = math.random(1, 5)
        it:replace(Sprites.Gems[r])
        it.item = r
        if animate then
          local c = copy(it.color)
          c.a = 1.0
          local tween1 = tween.new(Animation.Generate, it.color, c, 'linear')
          table.insert(self.animations, tween1)
        else
          it.color.a = 1.0
        end
      end
    end
  end
end

function Board:destroyGems(animate)
  local targets = {}

  for i=0, self.tx-1 do
    local prev = -1
    local target = {}
    for j=0, self.ty-1 do
      local it = self.tiles[i][j]
      if it.item == prev then
        table.insert(target, it)
      else
        if #target >= 3 then
          table.insert(targets, target)
        end
        target = { it }
      end
      prev = it.item
    end
    if #target >= 3 then
      table.insert(targets, target)
    end
  end

  for j=0, self.ty-1 do
    local prev = -1
    local target = {}
    for i=0, self.tx-1 do
      local it = self.tiles[i][j]
      if it.item == prev then
        table.insert(target, it)
      else
        if #target >= 3 then
          table.insert(targets, target)
        end
        target = { it }
      end
      prev = it.item
    end
    if #target >= 3 then
      table.insert(targets, target)
    end
  end

  for i, target in pairs(targets) do
    for j, it in pairs(target) do
      print(it.index.i .. ' ' .. it.index.j)
      it.removed = true
      it.score = it.score or 0
      it.score = it.score + #target

      if animate then
        local c = copy(it.color)
        c.a = 0
        local tween1 = tween.new(Animation.Destroy, it.color, c, 'linear')
        table.insert(self.animations, tween1)
      else
        it.color.a = 0
      end
    end
  end

  return #targets > 0
end

function Board:cancelMove(animate)
  self:moveTile(self.current, self.next, animate)
  self.current = nil
  self.next = nil
end

function Board:moveTile(a, b, animate)
  local i = a.index.i
  local j = a.index.j
  local i1 = b.index.i
  local j1 = b.index.j
  self.tiles[i][j], self.tiles[i1][j1] = self.tiles[i1][j1], self.tiles[i][j]
  a.index, b.index = b.index, a.index

  if animate then
    local tween1 = tween.new(Animation.Move, a.position, copy(b.position), 'linear')
    table.insert(self.animations, tween1)
    local tween2 = tween.new(Animation.Move, b.position, copy(a.position), 'linear')
    table.insert(self.animations, tween2)
  else
    a.position, b.position = b.position, a.position
  end
end

function Board:endMove(animate)
  if self:destroyGems(animate) then
    self.current = nil
    self.next = nil
    return true
  end
  return false
end
