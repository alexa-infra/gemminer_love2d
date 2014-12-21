function love.load()
  require('core')
  require('resource_manager')
  require('render_manager')
  require('sprite')
  require('board')

  Singletons:init()

  backgroundLayer = RenderManager:addLayer('background', 0)

  background = Sprite(Sprites.Background)
  backgroundLayer.sprites[1] = background

  board = Board(8, 8)
end

function love.draw()
  RenderManager:render()
end

function love.update(dt)
  board:update(dt)
end

function love.keypressed(key)
end

function love.mousereleased(x, y, button)
   if button == 'l' then
      board:click(x, y)
   end
end
