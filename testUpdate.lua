script_version('08.08.19')
local dlstatus = require('moonloader').download_status
local encoding = require('encoding')
encoding.default = 'CP1251'
u8 = encoding.UTF8
function main()
	while not isSampAvailable() do wait(222) end
	wait(1111)
	autoupdate('https://raw.githubusercontent.com/777qwerty777/pd/master/version.json', 'https://vk.com/id269473334')
	wait(-1)
end

function readAll(file)
    local f = assert(io.open(file, 'rb'))
    local content = f:read('*all')
    f:close()
    return content
end

function autoupdate(json_url, url)
	local json = getWorkingDirectory() .. '\\'..thisScript().name..'-version.json'
	if doesFileExist(json) then os.remove(json) end
		downloadUrlToFile(json_url, json,
		function(id, status, p1, p2)
			if status == dlstatus.STATUSEX_ENDDOWNLOAD then
				if doesFileExist(json) then
					local f = io.open(json, 'r')
					if f then
						local info = decodeJson(f:read('*a'))
						updatelink = info.updateurl
						updateversion = info.latest
						f:close()
						os.remove(json)
						if updateversion ~= thisScript().version then
							lua_thread.create(function()
								local color = -1
								sampAddChatMessage('���������� ����������. ������� ���������� c '..thisScript().version..' �� '..updateversion, color)
								wait(250)
								downloadUrlToFile(updatelink, thisScript().path,
								function(id3, status1, p13, p23)
									if status1 == dlstatus.STATUS_DOWNLOADINGDATA then
										print(string.format('��������� %d �� %d.', p13, p23))
									elseif status1 == dlstatus.STATUS_ENDDOWNLOADDATA then
										print('�������� ���������� ���������.')
										sampAddChatMessage('���������� ���������!', color)
										goupdatestatus = true
										lua_thread.create(function()
											wait(500)
											thisScript():reload()
										end)
									end
									if status1 == dlstatus.STATUSEX_ENDDOWNLOAD then
										if goupdatestatus == nil then
											sampAddChatMessage('���������� ������ ��������. �������� ���������� ������..', color)
											update = false
										end
									end
								end)
							end)
						else
							update = false
							print('v'..thisScript().version..': ���������� �� ���������.')
						end
					end
				else
					print('v'..thisScript().version..': �� ���� ��������� ����������. ��������� ��� ��������� �������������� �� '..url)
					update = false
				end
			end
		end)
	while update ~= false do wait(100) end
end
