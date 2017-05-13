--
-- Register Autonomous Agriculture to all vehicles
--

SpecializationUtil.registerSpecialization('AutoAgriculture', 'AutoAgriculture', g_currentModDirectory .. 'AutoAgriculture.lua');
AutoAgriculture = {};

function AutoAgriculture:loadMap(name)
	if self.firstRun == nil then
		self.firstRun = false;
		print("--LOADING AUTONOMOUS AGRICULTURE--")
		--[[
		for k, v in pairs(VehicleTypeUtil.vehicleTypes) do
			if v ~= nil then
				local allowInsertion = true;
				for i = 1, table.maxn(v.specializations) do
					local vs = v.specializations[i];
					if vs ~= nil and vs == SpecializationUtil.getSpecialization("drivable") then
						local v_name_string = v.name 
						local point_location = string.find(v_name_string, ".", nil, true)
						if point_location ~= nil then
							local _name = string.sub(v_name_string, 1, point_location-1);
							if rawget(SpecializationUtil.specializations, string.format("%s.AutoDrive", _name)) ~= nil then
								allowInsertion = false;								
							end;							
						end;
						if allowInsertion then	
							table.insert(v.specializations, SpecializationUtil.getSpecialization("AutoDrive"));
						end;
					end;
				end;
			end;	
		end;
		]]
	end;
end;

function AutoAgriculture:deleteMap()
  
end;

function AutoAgriculture:keyEvent(unicode, sym, modifier, isDown)

end;

function AutoAgriculture:mouseEvent(posX, posY, isDown, isUp, button)

end;

function AutoAgriculture:update(dt)
	
end;

function AutoAgriculture:draw()
  
end;

addModEventListener(AutoAgriculture);