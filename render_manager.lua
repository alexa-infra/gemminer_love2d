require('core')

local function Layer()
  local t = {}
  t.name = ""
  t.priority = 0
  t.visible = true
  t.sprites = {}
  return t
end

local function CmpLayers(a, b)
  return a.priority < b.priority
end

declare_singleton('RenderManager')

function RenderManager:init()
  self.layers = {}
  self.renderTable = {}
end

function RenderManager:render()
  for i, layer in ipairs(self.renderTable) do
    for j, sprite in ipairs(layer.sprites) do
      if sprite.image ~= nil then
        love.graphics.setColor(
          math.floor(255 * sprite.color.r),
          math.floor(255 * sprite.color.g),
          math.floor(255 * sprite.color.b),
          math.floor(255 * sprite.color.a))
        love.graphics.draw(sprite.image, sprite.quad,
          sprite.position.x, sprite.position.y)
      end
    end
  end
end

function RenderManager:addLayer(name, priority)
	local layer = Layer()
	layer.name = name
  layer.priority = priority
  layer.visible = true
	self.layers[name] = layer
  self:refreshRenderTable()
  return layer
end

function RenderManager:showLayer(name)
	assert(self.layers[name] ~= nil)
  if self.layers[name].visible then return end
	self.layers[name].visible = true
  self:refreshRenderTable()
end

function RenderManager:hideLayer(name)
	assert(self.layers[name] ~= nil)
  if self.layers[name].visible == false then return end
	self.layers[name].visible = false
  self:refreshRenderTable()
end

function RenderManager:getLayer(name)
  return self.layers[name]
end

function RenderManager:refreshRenderTable()
  self.renderTable = {}
  for i, layer in pairs(self.layers) do
    if layer.visible then
      self.renderTable[#self.renderTable + 1] = layer
    end
  end
  table.sort(self.renderTable, CmpLayers)
end
