require 'lib.moonloader'
require "lib.sampfuncs"

local memory = require 'memory'
local sampev = require "lib.samp.events"
local vkeys = require 'lib.vkeys'
local trace = 0
local bulletSync = {lastId = 0, maxLines = 30}
for i = 1, bulletSync.maxLines do
	bulletSync[i] = { other = {time = 0, t = {x,y,z}, o = {x,y,z}, type = 0, color = 0, id = -1, colorText = 0}}
end
local pool = {}
function create_empty_item()
	return {
		numbershots = 0,
		timenumbershots = 0,
		numberpromax = 0,
		timenumberpromax = 0,
		nick = '',
		quatX = 0.0,
		quatY = 0.0,
		quatZ = 0.0,
		positionX = 0.0,
		positionY = 0.0,
		positionZ = 0.0,
		timee = 0,
		aimcheck = 0,
		lines = {}
	}
end


math.round = function(num)
  local mult = 10^0
  return math.floor(num * mult + 0.5) / mult
end

function join_argb(a, r, g, b)
    local argb = b  -- b
    argb = bit.bor(argb, bit.lshift(g, 8))  -- g
    argb = bit.bor(argb, bit.lshift(r, 16)) -- r
    argb = bit.bor(argb, bit.lshift(a, 24)) -- a
    return argb
end

local font_flag = require('moonloader').font_flag

local fontss = renderCreateFont('Arial', 17, font_flag.BOLD + font_flag.SHADOW) --(название шрифта, размер шрифта, флаги[жирный и т.д.])


function getAmmoRecon()
	local result, recon_handle = sampGetCharHandleBySampPlayerId(idrecona)
	if result then
		local weapon = getCurrentCharWeapon(recon_handle)
		local struct = getCharPointer(recon_handle) + 0x5A0 + getWeapontypeSlot(weapon) * 0x1C
		return getStructElement(struct, 0x8, 4)
	end
end

function main()
	if not isSampLoaded() or not isSampfuncsLoaded() then return end
	while not isSampAvailable() do wait(0) end
	
	sampAddChatMessage(" AHelp by morreti loaded", 0xFFFFFF)
	
	sampRegisterChatCommand('trace', function()
	
		if trace == 0 then
			trace = 1
			sampAddChatMessage(" Трейсер пуль включен", -1)
		elseif trace == 1 then
			trace = 0
			sampAddChatMessage(" Трейсер пуль выключен", -1)
		end
		
	end)
	
	sampRegisterChatCommand('ban', function(i)
		local id, reason = string.match(i, '(%d+)%s*(.*)')
		if id == nil then sampAddChatMessage(" Введите: /ban [playerid] [причина]", -1) return end
		if #reason == 0 then sampAddChatMessage(" Введите: /ban [playerid] [причина]", -1) return end
		if sampIsPlayerConnected(id) then
			local _, my_id = sampGetPlayerIdByCharHandle(PLAYER_PED)
			local mynick = tostring(sampGetPlayerNickname(my_id):gsub('(.*_)', ''))
			sampSendChat("/a /ban ".. id .." ".. reason .." // ".. mynick .."")
		else
			sampAddChatMessage(" Игрок оффлайн", 0xAFAFAF)
		end
	end)
	
	sampRegisterChatCommand('warn', function(i)
		local id, reason = string.match(i, '(%d+)%s*(.*)')
		if id == nil then sampAddChatMessage(" Введите: /warn [playerid] [причина]", -1) return end
		if #reason == 0 then sampAddChatMessage(" Введите: /warn [playerid] [причина]", -1) return end
		if sampIsPlayerConnected(id) then
			local _, my_id = sampGetPlayerIdByCharHandle(PLAYER_PED)
			local mynick = tostring(sampGetPlayerNickname(my_id):gsub('(.*_)', ''))
			sampSendChat("/a /warn ".. id .." ".. reason .." // ".. mynick .."")
		else
			sampAddChatMessage(" Игрок оффлайн", 0xAFAFAF)
		end
	end)
	
	sampRegisterChatCommand('prison', function(i)
		local id, timee, reason = string.match(i, '(%d+) (%d+) %s*(.*)')
		if id == nil then sampAddChatMessage(" Введите: /prison [id игрока] [время] [причина]", -1) return end
		if timee == nil then sampAddChatMessage(" Введите: /prison [id игрока] [время] [причина]", -1) return end
		if #reason == 0 then sampAddChatMessage(" Введите: /prison [id игрока] [время] [причина]", -1) return end
		if sampIsPlayerConnected(id) then
			local _, my_id = sampGetPlayerIdByCharHandle(PLAYER_PED)
			local mynick = tostring(sampGetPlayerNickname(my_id):gsub('(.*_)', ''))
			sampSendChat("/a /prison ".. id .." ".. timee .." ".. reason .." // ".. mynick .."")
		else
			sampAddChatMessage(" Игрок оффлайн", 0xAFAFAF)
		end
	end)
	
	sampRegisterChatCommand('re', function(i)
	
		if #i == 0 then sampAddChatMessage(" Введите: /re [playerid / off]", -1) return end
		if i == "off" then  OffRecon() return end
		if i == "of" then  OffRecon() return end
		if i == "o" then  OffRecon() return end
		
		id = tonumber(i)
		
		if not i:match('(%d+)') then
			sampAddChatMessage(" Игрок оффлайн / не залогинен", 0xAFAFAF)
		else
			if not (select(1,sampGetCharHandleBySampPlayerId(id))) then
				sampAddChatMessage(" Игрок не в зоне стрима", 0xAFAFAF)
			else
				if sampIsPlayerConnected(id) then
					if inrecon == false then
						reconX, reconY, reconZ = getCharCoordinates(PLAYER_PED)
						reconAngle = getCharHeading(1)
					end
					inrecon = true
					idrecona = id
					local _, idzd = sampGetPlayerIdByCharHandle(PLAYER_PED)
					freezeCharPosition(playerPed, true)
					setCameraInFrontOfChar(select(2,sampGetCharHandleBySampPlayerId(id)))
					deleteMenu(menu)
					setGxtEntry("key1", "RMenu") -- 0ADF: add_dynamic_GXT_entry "GR2" text "Zero"
					setGxtEntry("key2", "Change")
					setGxtEntry("key3", "Stats")
					setGxtEntry("key4", "Weap")
					setGxtEntry("key5", "ResetShot")
					setGxtEntry("key6", "Help")
					setGxtEntry("key7", "Refresh")
					setGxtEntry("key8", "OFF")
					
					menu = createMenu('DUMMY', 550.0, 210.0, 50.0, 1, 1, 1, 1) -- 08D4: $1153 = create_panel_with_title 'IE09' position 29.0 170.0 width 180.0 columns 1 interactive 1 background 1 alignment 0// Imports
					setMenuColumn(menu, 0, 'key1', 'key2', 'key3', 'key4', 'key5', 'key6', 'key7', 'key8', 'DUMMY', 'DUMMY') -- 08DB: set_panel $1153 column 0 header 'DUMMY' data 'IE16' 'IE10' 'IE11' 'IE12' 'IE13' 'IE14' 'IE15' 'DUMMY' 'DUMMY' 'DUMMY' 'DUMMY' 'DUMMY'// Sunday // Monday // Tuesday // Wednesday // Thursday // Friday // Saturday
				else
					sampAddChatMessage(" Игрок оффлайн / не залогинен", 0xAFAFAF)
				end
			end
		end
	end)
	
	while true do
        wait(0)
		if inrecon == true then
			if sampIsPlayerConnected(idrecona) then
				if not pool[idrecona] or pool[idrecona].nick ~= sampGetPlayerNickname(idrecona) then pool[idrecona] = create_empty_item() end
				
				local nickrecona = sampGetPlayerNickname(idrecona)
				local onepercent = pool[idrecona].numbershots / pool[idrecona].numberpromax
				local percentshot = math.round(onepercent*100);
				
				local onepercentT = pool[idrecona].timenumbershots / pool[idrecona].timenumberpromax
				local percentshotT = math.round(onepercentT*100);
				local isPed, pPed = sampGetCharHandleBySampPlayerId(idrecona)
				local health, armor, ammo = sampGetPlayerHealth(idrecona), sampGetPlayerArmor(idrecona), getAmmoRecon()
				local speed, model, interior = getCharSpeed(pPed), getCharModel(pPed), getCharActiveInterior(playerPed)
				--local weaponID, ammo, Model = getCharWeaponInSlot(Ped ped, int slot)
				ammo = getAmmoRecon()
				armor = sampGetPlayerArmor(idrecona)
				if isPed then
					renderFontDrawText(fontss, string.format(''.. nickrecona ..'\n('..idrecona..')\n\n{00AA00}Level: {FFFFFF}'.. sampGetPlayerScore(idrecona)..'\n{fbec5d}Ping: {FFFFFF}'.. sampGetPlayerPing(idrecona)..'\n{AA0000}Health: {FFFFFF}'.. health ..'\n{AA0000}Armour: {FFFFFF}'.. armor ..'\n{00AA00}Speed: {FFFFFF}'.. math.floor(speed) ..'\n{8b00ff}Skin: {FFFFFF}'.. model ..'\n{fbec5d}Ammo: {FFFFFF}'.. ammo ..'\n{00AA00}Shot: {FFFFFF}'.. pool[idrecona].numberpromax ..' / '.. pool[idrecona].numbershots ..' : ' .. percentshot .. '%%\n{00AA00}TimeShot: {FFFFFF}'.. pool[idrecona].timenumberpromax ..' / '.. pool[idrecona].timenumbershots ..' : ' .. percentshotT .. '%%\n'), 122, 490, 0xFFFFFFFF)
				end
			end
		end
		local result, button = sampHasDialogRespond(202)
		if result then
			if button == 1 then
				if idrecona ~= nil then
					if sampIsPlayerConnected(idrecona) then
						if sampGetCurrentDialogEditboxText() == 0 then sampShowDialog(202, "ID игрока", "Введите ид игрока", "Готово", "Отмена", 1) return end
						InputText = sampGetCurrentDialogEditboxText()
						if not InputText:match('(%d+)') then
							sampAddChatMessage(" Игрок оффлайн / не залогинен", 0xAFAFAF)
							sampShowDialog(202, "ID игрока", "Введите ид игрока", "Готово", "Отмена", 1)
						else
							if not (select(1,sampGetCharHandleBySampPlayerId(id))) then sampAddChatMessage(" Игрок не в зоне стрима", 0xAFAFAF)
							else
								id = tonumber(InputText)
								inrecon = true
								idrecona = id
								local _, idzd = sampGetPlayerIdByCharHandle(PLAYER_PED)
								freezeCharPosition(playerPed, true)
								setCameraInFrontOfChar(select(2,sampGetCharHandleBySampPlayerId(id)))
							end
						end
					else
						sampAddChatMessage(" Игрок оффлайн / не залогинен", 0xAFAFAF)
						sampShowDialog(202, "ID игрока", "Введите ид игрока", "Готово", "Отмена", 1)
					end
				end
			end
		end
		if isKeyJustPressed(vkeys.VK_LSHIFT) and not sampIsChatInputActive() and not isSampfuncsConsoleActive() then
			if inrecon == true then
				sampSendMenuSelectRow(menu)
				najal = getMenuItemSelected(menu)
				if najal == 0 then
					sampShowDialog(202, "ID игрока", "Введите ид игрока", "Готово", "Отмена", 1)
					sampSendMenuQuit()
					deleteMenu(menu)
					while not isKeyDown(vkeys.VK_LSHIFT) do wait(0) return end
					wait(100)
					setGxtEntry("key1", "RMenu") -- 0ADF: add_dynamic_GXT_entry "GR2" text "Zero"
					setGxtEntry("key2", "Change")
					setGxtEntry("key3", "Stats")
					setGxtEntry("key4", "Weap")
					setGxtEntry("key5", "ResetShot")
					setGxtEntry("key6", "Help")
					setGxtEntry("key7", "Refresh")
					setGxtEntry("key8", "OFF")
					
					menu = createMenu('DUMMY', 550.0, 210.0, 50.0, 1, 1, 1, 1) -- 08D4: $1153 = create_panel_with_title 'IE09' position 29.0 170.0 width 180.0 columns 1 interactive 1 background 1 alignment 0// Imports
					setMenuColumn(menu, 0, 'key1', 'key2', 'key3', 'key4', 'key5', 'key6', 'key7', 'key8', 'DUMMY', 'DUMMY') -- 08DB: set_panel $1153 column 0 header 'DUMMY' data 'IE16' 'IE10' 'IE11' 'IE12' 'IE13' 'IE14' 'IE15' 'DUMMY' 'DUMMY' 'DUMMY' 'DUMMY' 'DUMMY'// Sunday // Monday // Tuesday // Wednesday // Thursday // Friday // Saturday
				end
				if najal == 1 then
					local nickrecona = sampGetPlayerNickname(idrecona)
					sampAddChatMessage(" Ник: ".. nickrecona .." Уровень: ".. sampGetPlayerScore(idrecona) .. " Пинг: "..sampGetPlayerPing(idrecona) .. "", -1)
					sampSendMenuQuit()
					deleteMenu(menu)
					while not isKeyDown(vkeys.VK_LSHIFT) do wait(0) return end
					wait(100)
					setGxtEntry("key1", "RMenu") -- 0ADF: add_dynamic_GXT_entry "GR2" text "Zero"
					setGxtEntry("key2", "Change")
					setGxtEntry("key3", "Stats")
					setGxtEntry("key4", "Weap")
					setGxtEntry("key5", "ResetShot")
					setGxtEntry("key6", "Help")
					setGxtEntry("key7", "Refresh")
					setGxtEntry("key8", "OFF")
					
					menu = createMenu('DUMMY', 550.0, 210.0, 50.0, 1, 1, 1, 1) -- 08D4: $1153 = create_panel_with_title 'IE09' position 29.0 170.0 width 180.0 columns 1 interactive 1 background 1 alignment 0// Imports
					setMenuColumn(menu, 0, 'key1', 'key2', 'key3', 'key4', 'key5', 'key6', 'key7', 'key8', 'DUMMY', 'DUMMY') -- 08DB: set_panel $1153 column 0 header 'DUMMY' data 'IE16' 'IE10' 'IE11' 'IE12' 'IE13' 'IE14' 'IE15' 'DUMMY' 'DUMMY' 'DUMMY' 'DUMMY' 'DUMMY'// Sunday // Monday // Tuesday // Wednesday // Thursday // Friday // Saturday
				end
				if najal == 2 then
					local nickrecona = sampGetPlayerNickname(idrecona)
					local result, handle = sampGetCharHandleBySampPlayerId(idrecona)
					local weapon = getCurrentCharWeapon(handle)
					local gunName = { [0] = "Кулак", "Кастет", "Клюшка", "Nightstick", "Кулак", "Кулак", "Кулак","Кулак", "Нож", "Бита", "Лопата", "Кий", "Катана", "Бензопила", "Дилдо", "Дилдо", "Вибратор", "Вибратор", "Цветы", "Трость", "Граната", "Газовая шашка", "Коктейль Молотова", "Pistol", "Desert Eagle", "Shotgun", "Sawnoff Shotgun", "Combat Shotgun", "Uzi", "MP5", "AK-47", "M4A1", "Tec-9", "Rifle", "Sniper Rifle", "RPG", "Heat Seeking RPG", "Flamethrower", "Minigun", "Satchel Charge", "Detonator", "Spraycan", "Fire Extinguisher", "Camera", "Night Vision Goggles", "Thermal Goggles", "Parachute" }
					sampAddChatMessage(" Ник: " .. nickrecona .. " Оружие: ".. gunName[weapon] .."", -1)
					sampSendMenuQuit()
					deleteMenu(menu)
					while not isKeyDown(vkeys.VK_LSHIFT) do wait(0) return end
					wait(100)
					setGxtEntry("key1", "RMenu") -- 0ADF: add_dynamic_GXT_entry "GR2" text "Zero"
					setGxtEntry("key2", "Change")
					setGxtEntry("key3", "Stats")
					setGxtEntry("key4", "Weap")
					setGxtEntry("key5", "ResetShot")
					setGxtEntry("key6", "Help")
					setGxtEntry("key7", "Refresh")
					setGxtEntry("key8", "OFF")
					
					menu = createMenu('DUMMY', 550.0, 210.0, 50.0, 1, 1, 1, 1) -- 08D4: $1153 = create_panel_with_title 'IE09' position 29.0 170.0 width 180.0 columns 1 interactive 1 background 1 alignment 0// Imports
					setMenuColumn(menu, 0, 'key1', 'key2', 'key3', 'key4', 'key5', 'key6', 'key7', 'key8', 'DUMMY', 'DUMMY') -- 08DB: set_panel $1153 column 0 header 'DUMMY' data 'IE16' 'IE10' 'IE11' 'IE12' 'IE13' 'IE14' 'IE15' 'DUMMY' 'DUMMY' 'DUMMY' 'DUMMY' 'DUMMY'// Sunday // Monday // Tuesday // Wednesday // Thursday // Friday // Saturday
				end
				if najal == 3 then
					pool[idrecona].timenumbershots = 0
					pool[idrecona].timenumberpromax = 0
					sampSendMenuQuit()
					deleteMenu(menu)
					while not isKeyDown(vkeys.VK_LSHIFT) do wait(0) return end
					wait(100)
					setGxtEntry("key1", "RMenu") -- 0ADF: add_dynamic_GXT_entry "GR2" text "Zero"
					setGxtEntry("key2", "Change")
					setGxtEntry("key3", "Stats")
					setGxtEntry("key4", "Weap")
					setGxtEntry("key5", "ResetShot")
					setGxtEntry("key6", "Help")
					setGxtEntry("key7", "Refresh")
					setGxtEntry("key8", "OFF")
					
					menu = createMenu('DUMMY', 550.0, 210.0, 50.0, 1, 1, 1, 1) -- 08D4: $1153 = create_panel_with_title 'IE09' position 29.0 170.0 width 180.0 columns 1 interactive 1 background 1 alignment 0// Imports
					setMenuColumn(menu, 0, 'key1', 'key2', 'key3', 'key4', 'key5', 'key6', 'key7', 'key8', 'DUMMY', 'DUMMY') -- 08DB: set_panel $1153 column 0 header 'DUMMY' data 'IE16' 'IE10' 'IE11' 'IE12' 'IE13' 'IE14' 'IE15' 'DUMMY' 'DUMMY' 'DUMMY' 'DUMMY' 'DUMMY'// Sunday // Monday // Tuesday // Wednesday // Thursday // Friday // Saturday
				end
				if najal == 4 then
					sampShowDialog(0, "Help", "{009933}Level:{FFFFFF} Левел игрока\n{009933}Ping:{FFFFFF} Пинг\n{009933}Health:{FFFFFF} Здоровье\n{009933}Armour:{FFFFFF} Броня\n{009933}Speed:{FFFFFF} Скорость транспорта\n{009933}Skin:{FFFFFF} Скин\n{009933}Ammo:{FFFFFF} Количество патронов на клиенте в обойме\n{009933}Shot:{FFFFFF} Количество выстрелов / Количество попаданий | Процент попаданий\n{C0C0C0}\tСервер подсчитывает количество выстрелов сделанных игроком, пока он онлайн\n\tНа глаз можно определить, использует ли игрок AIM\n{009933}TimeShot:{FFFFFF} Количество выстрелов / Количество попаданий | Процент попаданий\n{C0C0C0}\tТоже самое, что предыдущая строка, но счетчик обнуляется каждые 10 минут\n\tВ меню Recon можно обнулить в любой момент - \"ResetShot\"\n\n{009933}Change: {FFFFFF}переключить режим наблюдения на другого игрока\n{009933}Stats: {FFFFFF}выводит в чат краткую информацию\n\t{C0C0C0}Ник, Уровень, Пинг\n{009933}Weap: {FFFFFF}выводит в чат ник и оружие в руках игрока\n{009933}ResetShot: {FFFFFF}обнулить статистику выстрелов\n{009933}Refresh: {FFFFFF}обновить режим наблюдения\n{009933}OFF: {FFFFFF}выйти из режима наблюдения", "Закрыть", "", 0)
					sampSendMenuQuit()
					deleteMenu(menu)
					while not isKeyDown(vkeys.VK_LSHIFT) do wait(0) return end
					wait(100)
					setGxtEntry("key1", "RMenu") -- 0ADF: add_dynamic_GXT_entry "GR2" text "Zero"
					setGxtEntry("key2", "Change")
					setGxtEntry("key3", "Stats")
					setGxtEntry("key4", "Weap")
					setGxtEntry("key5", "ResetShot")
					setGxtEntry("key6", "Help")
					setGxtEntry("key7", "Refresh")
					setGxtEntry("key8", "OFF")
					
					menu = createMenu('DUMMY', 550.0, 210.0, 50.0, 1, 1, 1, 1) -- 08D4: $1153 = create_panel_with_title 'IE09' position 29.0 170.0 width 180.0 columns 1 interactive 1 background 1 alignment 0// Imports
					setMenuColumn(menu, 0, 'key1', 'key2', 'key3', 'key4', 'key5', 'key6', 'key7', 'key8', 'DUMMY', 'DUMMY') -- 08DB: set_panel $1153 column 0 header 'DUMMY' data 'IE16' 'IE10' 'IE11' 'IE12' 'IE13' 'IE14' 'IE15' 'DUMMY' 'DUMMY' 'DUMMY' 'DUMMY' 'DUMMY'// Sunday // Monday // Tuesday // Wednesday // Thursday // Friday // Saturday
				end
				if najal == 5 then
					inrecon = true
					idrecona = id
					local _, idzd = sampGetPlayerIdByCharHandle(PLAYER_PED)
					freezeCharPosition(playerPed, true)
					setCameraInFrontOfChar(select(2,sampGetCharHandleBySampPlayerId(id)))
					sampSendMenuQuit()
					deleteMenu(menu)
					while not isKeyDown(vkeys.VK_LSHIFT) do wait(0) return end
					wait(100)
					setGxtEntry("key1", "RMenu") -- 0ADF: add_dynamic_GXT_entry "GR2" text "Zero"
					setGxtEntry("key2", "Change")
					setGxtEntry("key3", "Stats")
					setGxtEntry("key4", "Weap")
					setGxtEntry("key5", "ResetShot")
					setGxtEntry("key6", "Help")
					setGxtEntry("key7", "Refresh")
					setGxtEntry("key8", "OFF")
					
					menu = createMenu('DUMMY', 550.0, 210.0, 50.0, 1, 1, 1, 1) -- 08D4: $1153 = create_panel_with_title 'IE09' position 29.0 170.0 width 180.0 columns 1 interactive 1 background 1 alignment 0// Imports
					setMenuColumn(menu, 0, 'key1', 'key2', 'key3', 'key4', 'key5', 'key6', 'key7', 'key8', 'DUMMY', 'DUMMY') -- 08DB: set_panel $1153 column 0 header 'DUMMY' data 'IE16' 'IE10' 'IE11' 'IE12' 'IE13' 'IE14' 'IE15' 'DUMMY' 'DUMMY' 'DUMMY' 'DUMMY' 'DUMMY'// Sunday // Monday // Tuesday // Wednesday // Thursday // Friday // Saturday
				end
				if najal == 6 then
					sampSendMenuQuit()
					deleteMenu(menu)
					OffRecon()
				end
			end
		end
		
        local oTime = os.time()
		
        if trace == 1 then
            for i = 1, bulletSync.maxLines do
                if bulletSync[i].other.time >= oTime then
                    local result, wX, wY, wZ, wW, wH = convert3DCoordsToScreenEx(bulletSync[i].other.o.x, bulletSync[i].other.o.y, bulletSync[i].other.o.z, true, true)
                    local resulti, pX, pY, pZ, pW, pH = convert3DCoordsToScreenEx(bulletSync[i].other.t.x, bulletSync[i].other.t.y, bulletSync[i].other.t.z, true, true)
                    if result and resulti then
                        local xResolution = memory.getuint32(0x00C17044)
                        if wZ < 1 then
                            wX = xResolution - wX
                        end
                        if pZ < 1 then
                            pZ = xResolution - pZ
                        end 
                        renderDrawLine(wX, wY, pX, pY, 1, bulletSync[i].other.color)
                        renderDrawPolygon(pX, pY-1, 3 + 1, 3 + 1, 1 + 1, 1, bulletSync[i].other.color)
                    end
                end
            end
        end
	end
end

function sampev.onPlayerQuit(playerId, reason)
	if inrecon == true then
		if tonumber(playerId) == idrecona then
			printStyledString('~r~~n~PLAYER DISCONNECT', 5000, 5);
			OffRecon()
		end
	end
end


function sampev.onPlayerChatBubble(i, c, _, d, m)
	if inrecon then return {i, c, 100.0, d, m} end
end


function sampev.onPlayerStreamOut(playerid)
	if inrecon and playerid == idrecona then
		OffRecon()
	end
end

function onReceivePacket(packetID, bitStream)
	if packetID == 207 then
		local trash = raknetBitStreamReadInt8(bitStream)-- ingore first 8 bit
		local playerid = raknetBitStreamReadInt16(bitStream)
		if (select(1,sampGetCharHandleBySampPlayerId(playerid))) then
			if not pool[playerid] or pool[playerid].nick ~= sampGetPlayerNickname(playerid) then pool[playerid] = create_empty_item() end
			pool[playerid].nick = sampGetPlayerNickname(playerid)
			if raknetBitStreamReadBool(bitStream) then local lrkeys = raknetBitStreamReadInt16(bitStream) end 
			if raknetBitStreamReadBool(bitStream) then local udkeys = raknetBitStreamReadInt16(bitStream) end 
			local keysdata = raknetBitStreamReadInt16(bitStream)
			local posX = raknetBitStreamReadFloat(bitStream)
			local posY = raknetBitStreamReadFloat(bitStream)
			local posZ = raknetBitStreamReadFloat(bitStream)
			
			local quatX = raknetBitStreamReadFloat(bitStream)
			local quatY = raknetBitStreamReadFloat(bitStream)
			local quatZ = raknetBitStreamReadFloat(bitStream)
			
			local posDist = getDistanceBetweenCoords3d(pool[playerid].positionX, pool[playerid].positionY, pool[playerid].positionZ, posX, posY, posZ)
			
			local KEY_FIRE = 4
			local nickrecona = sampGetPlayerNickname(playerid)
			if posDist >= 18.0 and keysdata == KEY_FIRE then
				sampAddChatMessage(" <Warning> ".. nickrecona .."[".. playerid .."]: Возможно чит на телепорт", 0xFF0000)
			elseif posDist >= 18.0 and quatX == pool[playerid].quatX and quatY == pool[playerid].quatY and quatZ == pool[playerid].quatZ then
				sampAddChatMessage(" <Warning> ".. nickrecona .."[".. playerid .."]: Возможно Airbreak", 0xFF0000)
			end
			pool[playerid].positionX = posX 
			pool[playerid].positionY = posY 
			pool[playerid].positionZ = posZ
			pool[playerid].quatX = quatX
			pool[playerid].quatY = quatY
			pool[playerid].quatZ = quatZ
		end
	end
	if packetID == 200 then
		local trash = raknetBitStreamReadInt8(bitStream)-- ingore first 8 bit
		local playerid = raknetBitStreamReadInt16(bitStream)
		if (select(1,sampGetCharHandleBySampPlayerId(playerid))) then
			if not pool[playerid] or pool[playerid].nick ~= sampGetPlayerNickname(playerid) then pool[playerid] = create_empty_item() end
			local vehicleid = raknetBitStreamReadInt16(bitStream)
			local lrkeys = raknetBitStreamReadInt16(bitStream)
			local udkeys = raknetBitStreamReadInt16(bitStream)
			local keysdata = raknetBitStreamReadInt16(bitStream)
			
			local quatX = raknetBitStreamReadBool(bitStream)
			local quatX = raknetBitStreamReadBool(bitStream)
			local quatX = raknetBitStreamReadBool(bitStream)
			local quatX = raknetBitStreamReadBool(bitStream)
			local quatX = raknetBitStreamReadInt16(bitStream)
			local quatY = raknetBitStreamReadInt16(bitStream)
			local quatZ = raknetBitStreamReadInt16(bitStream)
			
			local posX = raknetBitStreamReadFloat(bitStream)
			local posY = raknetBitStreamReadFloat(bitStream)
			local posZ = raknetBitStreamReadFloat(bitStream)
			
			local posDist = getDistanceBetweenCoords3d(pool[playerid].positionX, pool[playerid].positionY, pool[playerid].positionZ, posX, posY, posZ)
			local KEY_FIRE = 4
			local nickrecona = sampGetPlayerNickname(playerid)
			if posDist >= 18.0 and quatX == pool[playerid].quatX and quatY == pool[playerid].quatY and quatZ == pool[playerid].quatZ then
				sampAddChatMessage(" <Warning> ".. nickrecona .."[".. playerid .."]: Возможно Car Airbreak", 0xFF0000)
			end
			pool[playerid].positionX = posX 
			pool[playerid].positionY = posY 
			pool[playerid].positionZ = posZ
			pool[playerid].quatX = quatX
			pool[playerid].quatY = quatY
			pool[playerid].quatZ = quatZ
		end
	end
	if packetID == 203 then
		local trash = raknetBitStreamReadInt8(bitStream)-- ingore first 8 bit
		local playerid = raknetBitStreamReadInt16(bitStream)
		local camMode = raknetBitStreamReadInt8(bitStream)
		local camFrontX = raknetBitStreamReadFloat(bitStream)
		local camFrontY = raknetBitStreamReadFloat(bitStream)
		local camFrontZ = raknetBitStreamReadFloat(bitStream)
		
		local camPosX = raknetBitStreamReadFloat(bitStream)
		local camPosY = raknetBitStreamReadFloat(bitStream)
		local camPosZ = raknetBitStreamReadFloat(bitStream)
		
		local aimZ = raknetBitStreamReadFloat(bitStream)
		
		if aimZ ~= aimZ then
			sampAddChatMessage(" <Warning> ".. nickrecona .."[".. playerid .."]: Возможно InvalidAimZ", 0xFF0000)
		end
		if camMode == 45 then
			sampAddChatMessage(" <Warning> ".. nickrecona .."[".. playerid .."]: Возможно Тряска камеры", 0xFF0000)
		end
	end
end

function OffRecon()
	if inrecon == true then
		inrecon = false
		restoreCamera();setCameraBehindPlayer()
		freezeCharPosition(playerPed, a)
		deleteMenu(menu)
	else
		return sampAddChatMessage("Вы не в режиме наблюдения", 0xAFAFAF)
	end
end

function sampev.onBulletSync(playerid, data)
	if not pool[playerid] or pool[playerid].nick ~= sampGetPlayerNickname(playerid) then pool[playerid] = create_empty_item() end
	pool[playerid].nick = sampGetPlayerNickname(playerid)
	pool[playerid].numberpromax = pool[playerid].numberpromax + 1
	pool[playerid].timenumberpromax = pool[playerid].timenumberpromax + 1
	local result, ped = sampGetCharHandleBySampPlayerId(playerid)
	if result then
		local posX, posY, posZ = getCharCoordinates(ped)
		if data.origin.z == posZ then
		sampAddChatMessage(" <Warning> ".. pool[playerid].nick .."[".. playerid .."]: Возможно Damager / Silent Aim", 0xFF0000)
		end
	end
	if data.targetType == 1 then 
		pool[playerid].numbershots = pool[playerid].numbershots + 1
		pool[playerid].timenumbershots = pool[playerid].timenumbershots + 1
		pool[playerid].aimcheck = pool[playerid].aimcheck + 1
		
		if data.weaponId == 24 then
			if pool[playerid].aimcheck >= 5 then
				sampAddChatMessage(" <Warning> ".. pool[playerid].nick .."[".. playerid .."]: Возможно Aim (попал 5 раз подряд из Deagle)", 0xFF0000)
				pool[playerid].aimcheck = 0
			end
		end
		
		if data.weaponId == 25 then
			if pool[playerid].aimcheck >= 10 then
				sampAddChatMessage(" <Warning> ".. pool[playerid].nick .."[".. playerid .."]: Возможно Aim (попал 10 раз подряд из Shotgun)", 0xFF0000)
				pool[playerid].aimcheck = 0
			end
		end
		
		if data.weaponId == 23 then
			if pool[playerid].aimcheck >= 5 then
				sampAddChatMessage(" <Warning> ".. pool[playerid].nick .."[".. playerid .."]: Возможно Aim (попал 5 раз подряд из Silenced Pistol)", 0xFF0000)
				pool[playerid].aimcheck = 0
			end
		end
		
		if data.weaponId == 33 then
			if pool[playerid].aimcheck >= 5 then
				sampAddChatMessage(" <Warning> ".. pool[playerid].nick .."[".. playerid .."]: Возможно Aim (попал 5 раз подряд из Rifle)", 0xFF0000)
				pool[playerid].aimcheck = 0
			end
		end
		
		if data.weaponId == 29 then
			if pool[playerid].aimcheck >= 10 then
				sampAddChatMessage(" <Warning> ".. pool[playerid].nick .."[".. playerid .."]: Возможно Aim (попал 10 раз подряд из MP5)", 0xFF0000)
				pool[playerid].aimcheck = 0
			end
		end
		
		if data.weaponId == 30 then
			if pool[playerid].aimcheck >= 15 then
				sampAddChatMessage(" <Warning> ".. pool[playerid].nick .."[".. playerid .."]: Возможно Aim (попал 15 раз подряд из AK47)", 0xFF0000)
				pool[playerid].aimcheck = 0
			end
		end
		
		if data.weaponId == 31 then
			if pool[playerid].aimcheck >= 15 then
				sampAddChatMessage(" <Warning> ".. pool[playerid].nick .."[".. playerid .."]: Возможно Aim (попал 15 раз подряд из M4)", 0xFF0000)
				pool[playerid].aimcheck = 0
			end
		end
		
		local dist = getDistanceBetweenCoords3d(data.target.x, data.target.y, data.target.z, posX, posY, posZ)
		if dist == 7 then
            sampAddChatMessage(" <Warning> ".. pool[playerid].nick .."[".. playerid .."]: Возможно PRO Aim", 0xFF0000)
        end
	end
	if data.targetType == 2 then
		local result, carhandle = sampGetCarHandleBySampVehicleId(data.targetId)
		if result then
			local idcar = getCarModel(carhandle)
			if idcar == 422 or idcar == 478 or idcar == 554 or idcar == 543 then
				local oTime = os.time()
				if oTime >= pool[playerid].timee then
					sampAddChatMessage(" <Warning> ".. pool[playerid].nick .."[".. playerid .."]: Возможно тушер мяса", 0xFF0000)
				end
				pool[playerid].timee = os.time() + 5
			end
		end
	end
	
	if data.targetType ~= 1  then
		pool[playerid].aimcheck = 0
	end
	local O, T = data.origin, data.target
	if data.targetType == 1 and not isLineOfSightClear(O.x, O.y, O.z, T.x, T.y, T.z, true, false, false, true, true) then
		sampAddChatMessage(" <Warning> ".. pool[playerid].nick .."[".. playerid .."]: Возможно чит на стрельбу сквозь стены", 0xFF0000)
	end
    if trace == 1 then
        if data.center.x ~= 0 then
            if data.center.y ~= 0 then
                if data.center.z ~= 0 then
                    bulletSync.lastId = bulletSync.lastId + 1
                    if bulletSync.lastId < 1 or bulletSync.lastId > bulletSync.maxLines then
                        bulletSync.lastId = 1
                    end
                    bulletSync[bulletSync.lastId].other.time = os.time() + 5
                    bulletSync[bulletSync.lastId].other.o.x, bulletSync[bulletSync.lastId].other.o.y, bulletSync[bulletSync.lastId].other.o.z = data.origin.x, data.origin.y, data.origin.z
                    bulletSync[bulletSync.lastId].other.t.x, bulletSync[bulletSync.lastId].other.t.y, bulletSync[bulletSync.lastId].other.t.z = data.target.x, data.target.y, data.target.z
                    bulletSync[bulletSync.lastId].other.type = data.targetType
                    if data.targetType == 1 then
                        bulletSync[bulletSync.lastId].other.color = join_argb(255, 255, 0, 0)
                    else
                        bulletSync[bulletSync.lastId].other.color = join_argb(255, 0, 0, 255)
                    end
                end
            end
        end
    end
end