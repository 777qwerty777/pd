local useMoon, moonloader = pcall(require, 'moonloader')
local useSampfuncs, sampfuncs = pcall(require, 'sampfuncs')
local useSampev, sampev = pcall(require, 'samp.events')
local useFfi, ffi = pcall(require, 'ffi')
local use3dvec, d3vec = pcall(require, 'vector3d')

function main()
	while not isSampAvailable() do wait(1111) end
	wait(500)
	qwerty(useMoon, '����������� ������: moonloader.lua')
	qwerty(useSampfuncs, '����������� ������: sampfuncs.lua')
	qwerty(useSampev, '����������� ������: SAMP.lua')
	qwerty(useFfi, '����������� ������: FFI.lua')
	qwerty(use3dvec, '����������� ������: 3dvec.lua')
end
function qwerty(t, s)
	if not t then sampAddChatMessage('[ERROR]' .. s, -1) end
end

function autoupdate(url, path, name)
	local update = true
	local updatestatus
	goupdatestatus = nil
	lua_thread.create(function(url, path, name)
		sampAddChatMessage('������ �������� ' .. name .. '.', 0xC7DE58)
		wait(250)
		downloadUrlToFile(url, path,
		function(id, status, p1, p2)
			if status == dlstatus.STATUS_DOWNLOADINGDATA then
				sampAddChatMessage(string.format('��������� %d �� %d.', p1, p2), 0xC7DE58)
			elseif status == dlstatus.STATUS_ENDDOWNLOADDATA then
				sampAddChatMessage('�������� ' .. name .. ' ���������!', 0xC7DE58)
				goupdatestatus = true
			end
			if status == dlstatus.STATUSEX_ENDDOWNLOAD then
				if goupdatestatus == nil then
					sampAddChatMessage('�������� ��������. ����������..', 0xC7DE58)
					update = false
				end
			end
		end)
	end, url, path, name)
	while update ~= false do wait(100) end
end
