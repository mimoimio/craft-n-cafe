local serviceModules = script.Services:GetChildren()
local services = {}
-- return;
-- local viewModules = script.Views:GetChildren()
-- print([[services initialization]])
for i, d in serviceModules do
	if d:IsA("ModuleScript") then
		-- print("requiring", d.Name)
		services[d.Name] = require(d)
	end
	-- print(("required %s / %s"):format(i, #serviceModules))
end

local initializeservices = {}
for i, s in services do
	if s.initialize and type(s.initialize) == "function" then
		-- print("initializing", i)
		table.insert(initializeservices, { name = i, fn = s.initialize })
	end
end
for i, s in initializeservices do
	s.fn()
	-- print(("%20s initialized %s / %s"):format(s.name, i, #initializeservices))
end

local startservices = {}
for i, s in services do
	if s.start and type(s.start) == "function" then
		-- print("initializing", i)
		table.insert(startservices, { name = i, fn = s.start })
	end
end
for i, s in startservices do
	s.fn()
	-- print(("%20s started %s / %s"):format(s.name, i, #startservices))
end
