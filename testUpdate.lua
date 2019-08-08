script_version('07.08.19')
local dlstatus = require('moonloader').download_status
local encoding = require('encoding')
encoding.default = 'CP1251'
u8 = encoding.UTF8
function main()
	while not isSampAvailable() do wait(222) end
	wait(1111)
	downloadUrlToFile('https://raw.githubusercontent.com/777qwerty777/pd/master/version.json', thisScript().path..'.txt',
	function(id, status, p1, p2)
		if status == dlstatus.STATUS_ENDDOWNLOADDATA then
			sampAddChatMessage(('[Testing]: Обновление завершено!'), -1)
			lua_thread.create(function()
				wait(300)
				local file = io.open(thisScript().path..'.txt', 'r')
				if file then
					local info = decodeJson(file:read('*a'))
					sampAddChatMessage(u8:decode(info.updateurl), -1)
					sampAddChatMessage(info.latest, -1)
					if info.latest ~= thisScript().version then
						sampAddChatMessage('Вышло обновление', -1)
						goupdate(info.latest, info.latest)
					else
						sampAddChatMessage('Свежая версия', -1)
					end
				end
				file:close()
			end)
		end
	end)
	wait(-1)
end

function update()
	local fpath = os.getenv('TEMP') .. '\\testing_version.json'
	downloadUrlToFile('https://gist.githubusercontent.com/atiZZZ/7507f7d4a51dc036bd275b96cc7bed38/raw/a78a8ef401c553c4309efd6a80075f56567c6c93/atiz', fpath,
	function(id, status, p1, p2)
		if status == dlstatus.STATUS_ENDDOWNLOADDATA then
			local f = io.open(fpath, 'r')
			if f then
				local info = decodeJson(f:read('*a'))
				updatelink = info.updateurl
				if info and info.latest then
					version = tonumber(info.latest)
					if version > tonumber(thisScript().version) then
						lua_thread.create(goupdate)
					else
						update = false
						sampAddChatMessage(('[Testing]: У вас и так последняя версия! Обновление отменено'), -1)
					end
				end
			end
		end
	end)
end

function goupdate(link, ver)
	sampAddChatMessage(('[Testing]: Обнаружено обновление. AutoReload может конфликтовать. Обновляюсь...'), -1)
	sampAddChatMessage(('[Testing]: Текущая версия: '..thisScript().version..". Новая версия: "..ver), -1)
	wait(300)
	downloadUrlToFile(link, thisScript().path,
	function(id3, status1, p13, p23)
		if status1 == dlstatus.STATUS_DOWNLOADINGDATA then
			sampAddChatMessage(string.format('Загружено %d из %d.', p13, p23), -1)
		elseif status1 == dlstatus.STATUS_ENDDOWNLOADDATA then
			lua_thread.create(function()
				wait(300)
				sampAddChatMessage(('[Testing]: Обновление завершено!'), -1)
				thisScript():reload()
			end)
		end
		if status1 == dlstatus.STATUSEX_ENDDOWNLOAD then
			sampAddChatMessage('Обновление прошло неудачно. Запускаю устаревшую версию..', -1)
		end
	end)
end
