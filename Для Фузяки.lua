local memory = require "memory"
local color = 0
function main()
	if not isSampLoaded() or not isSampfuncsLoaded() then return end
	while not isSampAvailable() do wait(200) end
	sampRegisterChatCommand('dcol', function(id)
		if sampIsPlayerConnected(id) then
			color = sampGetPlayerColor(id)
		end
	end)
	while true do wait(0)
		local x1, y1, z1 = getCharCoordinates(PLAYER_PED)
		local weapon = getCurrentCharWeapon(PLAYER_PED)
		local ammo = getAmmoInCharWeapon(PLAYER_PED, weapon)

		if (weapon == 24 or weapon == 25 or weapon == 33) and not sampIsChatInputActive() and not sampIsDialogActive() and isKeyJustPressed(16) and color > 0 then -- SHIFT
			for id = 0, 1004 do
				if sampIsPlayerConnected(id) then
					local result, ped = sampGetCharHandleBySampPlayerId(id)
					if result then
						local x2, y2, z2 = getCharCoordinates(ped)
						if getCharHealth(ped) > 0 and getDistanceBetweenCoords2d(x1, y1, x2, y2) < 100 then
							setCharAmmo(PLAYER_PED, weapon, ammo-1)
							BulletSync(1, id, x1, y1, z1, x2, y2, z2, math.random(-30, 30)/100, math.random(-30, 30)/100, math.random(-30, 30)/100, weapon)
							wait(300)
						end
					end
				end
			end
		end

		if weapon == 24 or weapon == 25 or weapon == 33 then
			local result, ped = getCharPlayerIsTargeting(PLAYER_HANDLE)
			if result and not sampIsChatInputActive() and not sampIsDialogActive() and isKeyJustPressed(18) then -- ALT
				local x2, y2, z2 = getCharCoordinates(ped)
				if getCharHealth(ped) > 0 then
					local _, id = sampGetPlayerIdByCharHandle(ped)
					setCharAmmo(PLAYER_PED, weapon, ammo-1)
					BulletSync(1, id, x1, y1, z1, x2, y2, z2, math.random(-30, 30)/100, math.random(-30, 30)/100, math.random(-30, 30)/100, weapon)
				end
			end
		end
	end
end
function BulletSync(byteType, sTargetID, fOriginX, fOriginY, fOriginZ, fTargetX, fTargetY, fTargetZ, fCenterX, fCenterY, fCenterZ, byteWeaponID)
  local struct = allocateMemory(40)
  setStructElement(struct, 0, 1, byteType)
  setStructElement(struct, 1, 2, sTargetID)
  setStructElement(struct, 3, 4, representFloatAsInt(fOriginX))
  setStructElement(struct, 7, 4, representFloatAsInt(fOriginY))
  setStructElement(struct, 11, 4, representFloatAsInt(fOriginZ))
  setStructElement(struct, 15, 4, representFloatAsInt(fTargetX))
  setStructElement(struct, 19, 4, representFloatAsInt(fTargetY))
  setStructElement(struct, 23, 4, representFloatAsInt(fTargetZ))
  setStructElement(struct, 27, 4, representFloatAsInt(fCenterX))
  setStructElement(struct, 31, 4, representFloatAsInt(fCenterY))
  setStructElement(struct, 35, 4, representFloatAsInt(fCenterZ))
  setStructElement(struct, 39, 1, byteWeaponID)
  sampSendBulletData(struct)
  freeMemory(struct)
end
