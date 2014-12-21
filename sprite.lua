require('core')
require('resource_manager')

Sprites = {}
Sprites.Background = "res/BackGround.jpg"
Sprites.Gems = {}
Sprites.Gems[1] = "res/Purple.png"
Sprites.Gems[2] = "res/Green.png"
Sprites.Gems[3] = "res/Red.png"
Sprites.Gems[4] = "res/Yellow.png"
Sprites.Gems[5] = "res/Blue.png"

class('Sprite', Object)

function Sprite:init(path)
  self.image = ResourceManager:texture(path)
  self.quad = love.graphics.newQuad(0, 0, self.image:getWidth(),
    self.image:getHeight(), self.image:getDimensions())
  self.position = { x = 0, y = 0 }
  self.color = { r = 1, g = 1, b = 1, a = 1 }
end

function Sprite:setPosition(x, y)
  self.position.x = x
  self.position.y = y
end

function Sprite:replace(path)
  self.image = ResourceManager:texture(path)
  self.quad = love.graphics.newQuad(0, 0, self.image:getWidth(),
    self.image:getHeight(), self.image:getDimensions())
end
