require('core')

declare_singleton('ResourceManager')

function ResourceManager:init()
  self.textures = {}
end

function ResourceManager:_loadTexture(path)
  assert(self.textures[path] == nil)
  local img = love.graphics.newImage(path)
  self.textures[path] = img
  return img
end

function ResourceManager:texture(path)
  local tex = self.textures[path]
  if tex ~= nil then
    return tex
  end
  return self:_loadTexture(path)
end
