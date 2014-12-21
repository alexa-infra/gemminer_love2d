Object = Object or {}

function class(name, base)

  local c = nil

  if(_G[name] == nil) then
    c = {}    -- a new class instance
  else
    c = _G[name]   -- modify existing instance :)
  end

  if(base == nil) then error("Base class doesn't exist, make sure your class was included in the right order or derive from Object") end
   -- our new class is a shallow copy of the base class!
   for i,v in pairs(base) do
     c[i] = v
   end
   c._base = base

   -- the class will be the metatable for all its objects,
   -- and they will look up their methods in it.
   c.__index = c

   -- expose a constructor which can be called by <classname>(<args>)
   local mt = {}
   mt.__call = function(class_tbl, ...)
     local obj = {}
     setmetatable(obj,c)
     if c.init then
         c.init(obj,...)
     else
        -- make sure that any stuff from the base class is initialized!
        if base and base.init then
          base.init(obj, ...)
        end
     end
     return obj
   end

   c.is_a = function(self, klass)
      local m = getmetatable(self)
      while m do
         if m == klass then return true end
         m = m._base
      end
      return false
   end
   setmetatable(c, mt)
   _G[name] = c
end

if not(Singletons) then
  print("New singleton registry")
  Singletons = {}
  Singletons.registry = {}
end

--Registers a singletons table and places it's name in the registry, also marks singleton as non broken x
function declare_singleton(name)
  if not(_G[name]) then
    print("New singleton: " .. name)
    _G[name] = {}
    table.insert(Singletons.registry, name)
  end
end

--Initializes all singletons in order of delcaration, must be called after all singletons have been included.
function Singletons:init()
  for i=1,#self.registry,1 do
    _G[self.registry[i]]:init()
  end
end

function Singletons:restore()
  for i=1,#self.registry,1 do
    print("Restoring singleton:" .. self.registry[i])
    if(_G[self.registry[i]].restore) then _G[self.registry[i]]:restore() end
  end
end

--Initializes all singletons in order of delcaration, must be called after all singletons have been included.
function Singletons:update()
  for i=1,#self.registry,1 do
    if(_G[self.registry[i]].update) then _G[self.registry[i]]:update() end
  end
end
