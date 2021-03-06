--[[
Copyright (c) 2014, Robert 'Bobby' Zenz
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

* Redistributions of source code must retain the above copyright notice, this
  list of conditions and the following disclaimer.

* Redistributions in binary form must reproduce the above copyright notice,
  this list of conditions and the following disclaimer in the documentation
  and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
--]]


--- Caelum is a module based system for managing humidity, temperature and
-- biomes.
--
-- It is very similar to TerraGenitor.
Caelum = {}


--- Creates a new instance of Caelum.
--
-- @param humidity_base_value Optional. The abse value for humidity, defaults
--                            to zero.
-- @param temperature_base_value Optional. The abse value for temperature,
--                               defaults to zero.
function Caelum:new(humidity_base_value, temperature_base_value)
	local instance = {
		biomes = List:new(),
		biomes_cache = BlockedCache:new(),
		default_biome = nil,
		humidity = TerraGenitor:new(humidity_base_value),
		initialized = false,
		temperature = TerraGenitor:new(temperature_base_value)
	}
	
	setmetatable(instance, self)
	self.__index = self
	
	return instance
end


--- Gets the map of the biomes for the given x and z coordinate.
-- The map is a 2D array of biomes with the first dimension being x, and
-- the second being z, starting at the given coordinates.
--
-- @param x The x coordinate.
-- @param z The z coordinate.
-- @param elevation_map The 2D array that contains the elevation values
--                      for the given x and z coordinates.
-- @return A map with the biomes starting at the given coordinates.
function Caelum:get_biome_map(x, z, elevation_map)
	if self.biomes_cache:is_cached(x, z) then
		return self.biomes_cache:get(x, z)
	end
	
	local humidity_map = self.humidity:get_map(x, z, elevation_map)
	local temperature_map = self.temperature:get_map(x, z, elevation_map)
	
	local map = {}
	
	for idxx = x, x + constants.block_size - 1, 1 do
		map[idxx] = {}
		
		for idxz = z, z + constants.block_size - 1, 1 do
			local elevation = elevation_map[idxx][idxz]
			local humidity = humidity_map[idxx][idxz]
			local temperature = temperature_map[idxx][idxz]
			
			local current_biome = self.default_biome
			
			self.biomes:foreach(function(biome)
				if biome:fits(idxx, idxz, elevation, humidity, temperature) then
					current_biome = biome
				end
			end)
			
			map[idxx][idxz] = current_biome
		end
	end
	
	self.biomes_cache:put(x, z, map)
	
	return map
end

--- Gets the humidity map for the given coordinates.
--
-- @param x The x coordinate.
-- @param z The z coordinate.
-- @param elevation_map The 2D array that contains the elevation values
--                      for the given x and z coordinates.
-- @return The humidity map, a 2D array of tables containing the values and
--         infos.
function Caelum:get_humidity_map(x, z, elevation_map)
	return self.humidity:get_map(x, z, elevation_map)
end

--- Gets the temperature map for the given coordinates.
--
-- @param x The x coordinate.
-- @param z The z coordinate.
-- @param elevation_map The 2D array that contains the elevation values
--                      for the given x and z coordinates.
-- @return The temperature map, a 2D array of tables containing the values and
--         infos.
function Caelum:get_temperature_map(x, z, elevation_map)
	return self.temperature:get_map(x, z, elevation_map)
end

--- Inits this instance and all modules.
--
-- Does nothing if this instance is already intialized.
--
-- @param noise_manager Optional. The NoiseManager to use for the init. Defaults
--                      to a new instance if not provided.
function Caelum:init(noise_manager)
	if self:is_initialized() == false then
		noise_manager = noise_manager or NoiseManager:new()
		
		self.humidity:init(noise_manager)
		self.temperature:init(noise_manager)
		
		self.initialized = true
	end
end

--- Gets if this instance has been initialized.
--
-- @return true if this instance has been initialized.
function Caelum:is_initialized()
	return self.initialized
end

--- Registers the given biome.
--
-- @param biome The biome to regiser.
function Caelum:register_biome(biome)
	self.biomes:add(biome)
end

--- Registers the given modile for the humidity map.
--
-- @param module The module to register.
function Caelum:register_humidity_module(module)
	self.humidity:register(module)
end

--- Registers the given module for the temperature map.
--
-- @param module The module to register.
function Caelum:register_temperature_module(module)
	self.temperature:register(module)
end

--- Sets the default biome that is used if no biomes fits.
--
-- @param biome The biome.
function Caelum:set_default_biome(biome)
	self.default_biome = biome
end

