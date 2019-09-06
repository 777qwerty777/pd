script_author('Gabriel_Montana')
-- ::INCLUDE
local sampev = require('samp.events')
local logins = {}
local dir_logins = string.format('%s\\moonloader\\config\\accounts.base', getGameDirectory())

if not doesFileExist(dir_logins) then
local file = io.open(dir_logins, 'a')
file:write('{}')
file:flush()
io.close(file)
end

local servers = {
    ['185.169.134.11'] = 'Revolution';
    ['185.169.134.34'] = 'Reborn';
    ['185.169.134.22'] = 'Legacy';
    ['185.169.134.20'] = 'Two';
}

function main()
    while not isSampAvailable() do wait(222) end
    tDialog = lua_thread.create_suspended(dialog) sampRegisterChatCommand('asdf', function() tDialog:run() end) load_base()
    logins = { -- DEBUG
        ['Gabriel_Montana1'] = {server = '185.169.134.11'}; ['Gabriel_Montana2'] = {server = '185.169.134.34'}; ['Gabriel_Montana3'] = {server = '185.169.134.22'}; ['Gabriel_Montana4'] = {server = '185.169.134.20'};
    }
    wait(-1)
end

function save_base()
    local file = io.open(dir_logins, 'a')
    file:write(encodeJson(logins))
    file:flush()
    io.close(file)
end

function load_base()
    local file = io.open(dir_logins, 'r')
    logins = decodeJson(file:read('*a'))
    io.close(file)
end

function getServer()
    return servers[sampGetCurrentServerAddress()]
end

function getNicknames()
    local n = {}
    for k, v in pairs(logins) do
        n[#n+1] = k
    end
    return n, #n
end

function dialog()
    ::Main::
    local nicks, size = getNicknames()
    local text = nicks table.insert(text, 1, '>>> Добавить\t')
    local bDialog, button, list, input = false, nil, nil, nil sampShowDialog(63333, 'Автологин', table.concat(text, '\n'), 'Выбрать', 'Закрыть', 4)
    wait(100)
    while not bDialog do
        wait(0)
        bDialog, button, list, input = sampHasDialogRespond(63333)
    end
    if button ~= 0 then
        if list == 0 then
            local nickname = sampGetPlayerNickname(select(2, sampGetPlayerIdByCharHandle(PLAYER_PED)))
            local temp_key = string.format ("%s\t(%s)",nickname,getServer())
            if logins[temp_key] == nil then
                logins[temp_key] = {
                    server = sampGetCurrentServerAddress();
                    pass1 = '';
                    pass2 = ''
                }
                save_base()
                ::CreatePassword::
                local bDialog, button, list, input = false, nil, nil, nil sampShowDialog(63332, 'Автологин :: пароль', 'Пароль для аккаунта: '..temp_key, 'Сохранить', 'Назад', 3)
                wait(100)
                while not bDialog do
                    wait(0)
                    bDialog, button, list, input = sampHasDialogRespond(63332)
                end
                if button ~= 0 then
                    if input:len() ~= 0 then
                        logins[temp_key].pass1 = input
                        ::CreateIp::
                        local bDialog, button, list, input = false, nil, nil, nil sampShowDialog(63331, 'Автологин :: пароль', 'IP пароль для аккаунта: '..temp_key, 'Сохранить', 'Назад', 3)
                        wait(100)
                        while not bDialog do
                            wait(0)
                            bDialog, button, list, input = sampHasDialogRespond(63331)
                        end
                        if button ~= 0 then
                            if input:len() ~= 0 then
                                logins[temp_key].pass2 = input
                                goto Main
                            else
                                goto CreateIp
                            end
                        else
                            goto Main
                        end
                    else
                        goto CreatePassword
                    end
                else
                    goto Main
                end
            else
                sampAddChatMessage('Аккаунт существует', -1)
            end
        else
            sampAddChatMessage('Выбран аккаунт: ' .. text[list+1], -1)
            ::EritorAccount::
            local bDialog, button, list, input = false, nil, nil, nil
            local acc_key = text[list+1]
            local aText = string.format('Аккаунт:\t%s\nПароль:\t%s\nIP пароль:\t%s', acc_key, logins[acc_key].pass1, logins[acc_key].pass2) sampShowDialog(63330, 'Автологин :: ' .. text[list+1], aText, 'Изменить', 'Назад', 4)
            wait(100)
            while not bDialog do
                wait(0)
                bDialog, button, list, input = sampHasDialogRespond(63330)
            end
        end
    -- else -- Main dialog exit
    end
end
