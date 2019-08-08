script_version('08.08.19')
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
			sampAddChatMessage(('[Testing]: ���������� ���������!'), -1)
			lua_thread.create(function()
				wait(300)
				local file = io.open(thisScript().path..'.txt', 'r')
				if file then
					local info = decodeJson(file:read('*a'))
					sampAddChatMessage(u8:decode(info.updateurl), -1)
					sampAddChatMessage(info.latest, -1)
					if info.latest ~= thisScript().version then
						sampAddChatMessage('����� ����������', -1)
					else
						sampAddChatMessage('������ ������', -1)
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
						sampAddChatMessage(('[Testing]: � ��� � ��� ��������� ������! ���������� ��������'), -1)
					end
				end
			end
		end
	end)
end

function goupdate()
	sampAddChatMessage(('[Testing]: ���������� ����������. AutoReload ����� �������������. ����������...'), -1)
	sampAddChatMessage(('[Testing]: ������� ������: '..thisScript().version..". ����� ������: "..version), -1)
	wait(300)
	downloadUrlToFile(updatelink, thisScript().path,
	function(id3, status1, p13, p23)
		if status1 == dlstatus.STATUS_ENDDOWNLOADDATA then
			sampAddChatMessage(('[Testing]: ���������� ���������!'), -1)
			thisScript():reload()
		end
	end)
end
