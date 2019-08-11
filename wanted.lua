local sampev, imgui, encoding, inicfg, vkeys = require('samp.events'), require('imgui'), require('encoding'), require('inicfg'), require('vkeys')
local dlstatus = require('moonloader').download_status
encoding.default = 'CP1251'
u8 = encoding.UTF8
script_version('11.08.19 18')
require('moonloader')


-- ########### :: VARS :: ###########
-- ########### :: VARS :: ###########
local isGetAmmo = false
local editKeys = 0
local mouse = false
local isRed = false
local varId = -1
local antiflood = os.clock() * 1000

local default_colors = {
	[1]  = imgui.ImColor(240, 240, 240, 240):GetU32();   -- Text
	[3]  = imgui.ImColor(003, 003, 000, 200):GetU32();   -- WindowBg
	[6]  = imgui.ImColor(110, 110, 127, 127):GetU32();   -- Border
	[8]  = imgui.ImColor(031, 031, 031, 240):GetU32();   -- FrameBg
	[9]  = imgui.ImColor(114, 114, 114, 216):GetU32();   -- FrameBgHovered
	[10] = imgui.ImColor(160, 160, 160, 160):GetU32();   -- FrameBgActive
	[12] = imgui.ImColor(012, 026, 046, 236):GetU32();   -- TitleBgActive
	[23] = imgui.ImColor(012, 026, 046, 236):GetU32();   -- Button
	[24] = imgui.ImColor(104, 104, 104, 255):GetU32();   -- ButtonHovered
	[25] = imgui.ImColor(130, 130, 130, 255):GetU32();   -- ButtonActive
	[26] = imgui.ImColor(160, 160, 160, 060):GetU32();   -- Header
	[27] = imgui.ImColor(160, 160, 160, 060):GetU32();   -- HeaderHovered
	[28] = imgui.ImColor(160, 160, 160, 030):GetU32();   -- HeaderActive
	[38] = imgui.ImColor(031, 031, 031, 240):GetU32();   -- PlotLines / PlotHistogram (не активный)
	[40] = imgui.ImColor(229, 178, 000, 255):GetU32();   -- PlotHistogram (активный)
	[41] = imgui.ImColor(240, 240, 240, 240):GetU32();   -- PlotHistogramHovered / текст уведомления
	[43] = imgui.ImColor(012, 026, 046, 236):GetU32();   -- ChildWindowBg
}

local DIR = string.format('%s\\moonloader\\config\\WANTED', getGameDirectory())
if not doesDirectoryExist(DIR) then createDirectory(DIR) end
local DIR_INI = string.format('%s\\wanted.cfg', DIR)
local DIR_WANTED = string.format("%s\\WANTED.wn", DIR)
if not doesFileExist(DIR_INI) then
	local text = '[colors]'
	for k, v in pairs(default_colors) do
		text = string.format('%s\n%s=%s', text, k, v)
	end
	text = string.format('%s\n[float]\n1=4.0\n2=4.0\n3=4.0\n[key]\nwanted=73\npursuit=71\nammo=113\n[ammo]\nshotgun=true\ndeagle=true\nsmg=false\nm4=true\nrifle=true\narmour=true\ngranate=false', text)
	local file = io.open(DIR_INI, 'a')
	file:write(text)
	file:flush()
	io.close(file)
end
local ini = inicfg.load(nil, DIR_INI)
if not ini.key.ammo then ini.key.ammo = 113;    inicfg.save(ini, DIR_INI) end
if ini.ammo == nil then
	ini.ammo = {
		deagle  = true;
		shotgun = true;
		smg     = false;
		m4      = true;
		rifle   = true;
		armour  = true;
		granate = false;
	}
	inicfg.save(ini, DIR_INI)
end

-- ########### :: TABLE :: ###########
local masked, wanted, notif, font = {}, {}, {}, {}

local hotKey = {
	pursuit = imgui.ImBuffer(tostring(ini.key.pursuit), 256);
	wanted  = imgui.ImBuffer(tostring(ini.key.wanted), 256);
	ammo    = imgui.ImBuffer(tostring(ini.key.ammo), 256)
}
local IM = {
	Want = imgui.ImBool(false);
	Styl = imgui.ImBool(false);
	Bind = imgui.ImBool(false);

	shotgun = imgui.ImBool(ini.ammo.shotgun);
	deagle  = imgui.ImBool(ini.ammo.deagle);
	smg     = imgui.ImBool(ini.ammo.smg);
	m4      = imgui.ImBool(ini.ammo.m4);
	rifle   = imgui.ImBool(ini.ammo.rifle);
	armour  = imgui.ImBool(ini.ammo.armour);
	granate = imgui.ImBool(ini.ammo.granate);

	Buf1 = imgui.ImBuffer(256);
	Buf2 = imgui.ImBuffer(256);
	Buf3 = imgui.ImBuffer(256);

	float1 = imgui.ImFloat(ini.float[1]);
	float2 = imgui.ImFloat(ini.float[2]);
	float3 = imgui.ImFloat(ini.float[3]);

	cStat = imgui.ImInt(0);
	cPods = imgui.ImInt(0);
	cStar = imgui.ImInt(0);

	Selc = 1;

	mStat = 20;
	mPods = 10;

	sStat = 1;
	sPods = 1;
}

local setTable, setAmmo = {
	['Поле ввода'] = {
		[8]  = 'Без эффектов';
		[9]  = 'При наведении';
		[10] = 'При нажатии';
	};
	['Списки'] = {
		[26] = 'Без эффектов';
		[27] = 'При наведении';
		[28] = 'При нажатии';
	};
	['Окна'] = {
		[12] = 'Заголовок';
		[3]  = 'Фон окна';
		[6]  = 'Разделители';
		[1]  = 'Текст';
	};
	['Кнопки'] = {
		[23] = 'Без эффектов';
		[24] = 'При наведении';
		[25] = 'При нажатии';
	};
	['Уведомление'] = {
		[38] = 'Фон полоски';
		[40] = 'Полоска';
		[41] = 'Текст';
		[43] = 'Фон окна';
	}
}, {
	{'Deagle'; 'deagle'};
	{'Shotgun'; 'shotgun'};
	{'SMG'; 'smg'};
	{'M4A1'; 'm4'};
	{'Rifle'; 'rifle'};
	{'Броня'; 'armour'};
	{'Спец оружие'; 'granate'};
}

local copColor = {
	[3]  = {5; 19}; -- WindowBg;      PopupBg;     ComboBg
	[6]  = {29};    -- Border;        Separator
	[8]  = {15};    -- FrameBg;       ScrollbarBg
	[12] = {11};    -- TitleBg;       TitleBgActive
	[23] = {16};    -- Button;        ScrollbarGrab
	[24] = {17};    -- ButtonHovered; ScrollbarGrabHovered
	[25] = {18};    -- ButtonActive;  ScrollbarGrabActive
}
local style = imgui.GetStyle()
local colors = style.Colors

local ToScreen = convertGameScreenCoordsToWindowScreenCoords

-- ########### :: COMBO ITEMS :: ###########
local items_stat, items_pod, items_star = {}, {}, {'1';'2';'3';'4';'5';'6'}


local SendWanted = lua_thread.create_suspended(function(...)
	repeat wait(0) until math.ceil(os.clock() * 1000 - antiflood) > math.random(1100, 1200)
	if not getPlayerMask(varId) then sampSendChat(...) end
	wait(800)
	repeat wait(0) until math.ceil(os.clock() * 1000 - antiflood) > math.random(1100, 1200)
	if not getPlayerMask(varId) then sampSendChat('/ps '..varId) end
	wait(800)
end)
local SendPursuit = lua_thread.create_suspended(function(id)
	repeat wait(0) until math.ceil(os.clock() * 1000 - antiflood) > math.random(1100, 1200)
	if not getPlayerMask(id) then sampSendChat('/ps ' .. id) end
end)
local GetAmmo = lua_thread.create_suspended(function() isGetAmmo = true; wait(3500); isGetAmmo = false end)

-- ########### :: VARS :: ###########
-- ########### :: VARS :: ###########


for k, v in pairs(ini.colors) do
	colors[k] = imgui.ImColor(v):GetVec4()
end
for k, v in pairs(copColor) do
	for _, iv in ipairs(copColor[k]) do
		colors[iv] = colors[k]
	end
end

imgui.ShowCursor = false

function main()
	while not isSampAvailable() do wait(111) end
	autoupdate('https://raw.githubusercontent.com/777qwerty777/pd/master/version.json', 'https://vk.com/id269473334')
	if not doesFileExist(DIR_WANTED) then
		local file = io.open(DIR_WANTED, 'a')
		wanted = {
			[1] = {
				title = 'Убийство';
				[1] = {
					title = 'Убийство без применения огнестрельного оружия';
					star = 3;
					text = '';
				};
				[2] = {
					title = 'Убийство с применением огнестрельного оружия';
					star = 4;
					text = 'Лишение лиц. на оружие';
				};
				[3] = {
					title = 'Убийство по неосторожности / превышение обороны';
					star = 2;
					text = 'Только если сам сдался';
				};
			};
			[2] = {
				title = 'Вред здоровью';
				[1] = {
					title = 'Вред здоровью без огнестрела, без смерти';
					star = 1;
					text = '';
				};
				[2] = {
					title = 'Вред здоровью с огнестрелом, без смерти';
					star = 3;
					text = '';
				};
				[3] = {
					title = 'Неумышленный вред здоровью, без смерти';
					star = 1;
					text = 'Или Испр. Раб';
				};
				[4] = {
					title = 'Попытка суицида, подстрекательство к суициду';
					star = 1;
					text = '';
				};
			};
			[3] = {
				title = 'Запрещенка';
				[1] = {
					title = 'Сбыт, приобретение, изготовление запрещенки';
					star = 4;
					text = '';
				};
				[2] = {
					title = 'Использование / хранение запрещенки без цели сбыта';
					star = 2;
					text = 'При добровольной сдаче - без розыска';
				};
			};
			[4] = {
				title = 'Имущество';
				[1] = {
					title = '(ГР) Непр. владение, польз., распоряжение, порча';
					star = 2;
					text = 'Факт угона - изъятие ВУ';
				};
				[2] = {
					title = '(ГОС) Непр. владение, польз., распоряжение, порча';
					star = 4;
					text = 'Факт угона - изъятие ВУ';
				};
			};
			[5] = {
				title = 'Ложные показания';
				[1] = {
					title = 'Дача ложных показаний сотрудникам прав. органов';
					star = 3;
					text = '';
				};
			};
			[6] = {
				title = 'Терроризм/похищение';
				[1] = {
					title = 'Организация/участие/осуществление терракта';
					star = 6;
					text = 'Изъятие лицензии на оружие';
				};
				[2] = {
					title = 'Похищение/взятие  в заложники человека';
					star = 5;
					text = 'Изъятие лицензии на оружие';
				};
			};
			[7] = {
				title = 'Проникновение';
				[1] = {
					title = 'Проникновение на охраняемые гос. стр. территории';
					star = 3;
					text = 'Без разрешения ст.состава орг.\nНе сдать запрещенку/написать заяву.\nНе адвоката на парковку';
				};
				[2] = {
					title = 'Проникновение в частную собственность';
					star = 2;
					text = '';
				};
			};
			[8] = {
				title = 'Уклонение от ответ.';
				[1] = {
					title = 'Неподчинение законному требованию полиции, ФБР';
					star = 2;
					text = '';
				};
				[2] = {
					title = 'Отказ/уклонение от оплаты штрафа';
					star = 2;
					text = '';
				};
				[3] = {
					title = 'Побег из-под стражи/места лишения свободы/задерж.';
					star = 6;
					text = '';
				};
				[4] = {
					title = 'Уход с места ДТП';
					star = 2;
					text = 'Изъятие ВУ';
				};
			};
			[9] = {
				title = 'Взятка/налоги';
				[1] = {
					title = 'Дача/получение взятки должностным лиому';
					star = 3;
					text = 'Санкция по ФП';
				};
				[2] = {
					title = 'Уклонение от уплаты налогов';
					star = 6;
					text = 'Или 3 года + 5к';
				};
				[3] = {
					title = 'Ведение теневого бизнеса';
					star = 3;
					text = 'Закрытие биза';
				};
				[4] = {
					title = 'Сокрытие доходов бизнес организации';
					star = 5;
					text = 'Закрытие биза';
				};
			};
			[10] = {
				title = 'Хулиганство';
				[1] = {
					title = 'Вымогательство';
					star = 2;
					text = '';
				};
				[2] = {
					title = 'Срыв государственного мероприятия';
					star = 6;
					text = '';
				};
				[3] = {
					title = 'Угроза убийством или вредом здоровью';
					star = 3;
					text = '';
				};
				[4] = {
					title = 'Воспрепятств. выполнению служ. обязанностей';
					star = 1;
					text = '';
				};
			};
		}
		save_wanted()
	end
	load_wanted()
	generate_items_stat()
	generate_items_pod()

	imgui.Process = true;
	wait(5)
	showCursor(false, false)
	while true do wait(0)

		local result, target = getCharPlayerIsTargeting(PLAYER_HANDLE)
		if result and isKeysDown(hotKey.wanted.v) then
			local result2, playerid = sampGetPlayerIdByCharHandle(target)
			if result2 and playerid > -1 --[[and not getPlayerMask(playerid)]] then
				varId = playerid
				IM.Want.v = true
			end
		end
		if result and isKeysDown(hotKey.pursuit.v) then
			local result2, playerid = sampGetPlayerIdByCharHandle(target)
			if result2 and playerid > -1 --[[and not getPlayerMask(playerid)]] then
				varId = playerid
				SendPursuit:run(playerid)
			end
		end
		if isKeysDown(hotKey.ammo.v) and chat_cont() and sampIsDialogActive() and sampGetCurrentDialogId() == 245 then
			GetAmmo:run()
			sampSendDialogResponse(245, 1, 10, nil)
		end


		if isRed and not IM.Want.v then isRed = false end
		if IM.Want.v or IM.Styl.v or IM.Bind.v then
			if not mouse then
				mouse = true; showCursor(true, false)
			end
		elseif mouse then
			mouse = false; showCursor(false, false)
		end

	end
end

function imgui.BeforeDrawFrame()
	if not bFontChanged then
		imgui.SwitchContext()
		imgui.GetIO().Fonts:Clear()
		local ranges = imgui.GetIO().Fonts:GetGlyphRangesCyrillic()
		imgui.GetIO().Fonts:AddFontFromFileTTF(getFolderPath(0x14) .. '\\trebucbd.ttf', 14, nil, ranges)
		font[0] = imgui.GetIO().Fonts:AddFontFromFileTTF(getFolderPath(0x14) .. '\\trebucbd.ttf', 14, nil, ranges)
		for i = 14, 25 do
			font[i] = imgui.GetIO().Fonts:AddFontFromFileTTF(getFolderPath(0x14) .. '\\arialbd.ttf', i, nil, ranges)
		end
		imgui.RebuildFonts()
		bFontChanged = true
	end
end

function imgui.OnDrawFrame()
	if not resX and not resY then resX, resY = getScreenResolution() end
	if IM.Want.v then
		imgui.PushFont(isFullHD() and font[19] or font[0])
		local sizeX, sizeY, sizeY_red = isFullHD() and 816 or 550, isFullHD() and 372 or 255, isFullHD() and 462 or 328
		imgui.SetNextWindowSize(imgui.ImVec2(sizeX, isRed and sizeY_red or sizeY), imgui.Cond.Appearing)
	    imgui.SetNextWindowPos(imgui.ImVec2(resX/2, resY/2), imgui.Cond.Appearing, imgui.ImVec2(0.5, 0.5))
		if not IM.Styl.v then imgui.SetNextWindowFocus() end
	    imgui.Begin(u8'Выдать розыск', IM.Want, imgui.WindowFlags.NoScrollbar + imgui.WindowFlags.NoResize + imgui.WindowFlags.NoMove + imgui.WindowFlags.NoCollapse + imgui.WindowFlags.AlwaysUseWindowPadding)
		if isRed and imgui.GetWindowHeight() == sizeY then
			imgui.SetWindowSize(imgui.ImVec2(sizeX, sizeY_red)); imgui.SetWindowPos(imgui.ImVec2((resX-sizeX)/2, (resY-sizeY_red)/2))
		elseif not isRed and imgui.GetWindowHeight() == sizeY_red then
			imgui.SetWindowSize(imgui.ImVec2(sizeX, sizeY)); imgui.SetWindowPos(imgui.ImVec2((resX-sizeX)/2, (resY-sizeY)/2))
		end
		imgui.PushStyleVar(imgui.StyleVar.WindowPadding, imgui.ImVec2(8, isFullHD() and 6 or 4))
		imgui.BeginChild(u8'##Список :: Статей', imgui.ImVec2(getFullHD(170), getFullHD(219)), true)
		for i = 1, 20 do
			if wanted[i] then
				if imgui.Selectable(u8(('[%d] %s'):format(i, wanted[i].title)), IM.Selc == i) then
				    IM.Selc = i;
					IM.cStat.v = i - 1
					IM.cPods.v = 0
					generate_items_stat()
					generate_items_pod()
				end
			end
		end
		imgui.EndChild()
		imgui.PopStyleVar()
		imgui.SameLine(nil, getFullHD(3))
		imgui.BeginChild(u8'##Список :: Подстатей', imgui.ImVec2(getFullHD(361), getFullHD(219)), true)
		imgui.SetCursorPosY(imgui.GetCursorPosY() - 2)

		for i = 1, IM.mPods do
			if wanted[IM.Selc] and wanted[IM.Selc][i] and type(wanted[IM.Selc][i]) == 'table' then

				imgui.SetCursorPosX(imgui.GetCursorPosX() - 3)

				local text = u8(string.format('[%d.%d] %s', IM.Selc, i, wanted[IM.Selc][i].title))

				if imgui.Button(text, imgui.ImVec2(getFullHD(350), 0)) and not isRed and varId ~= -1 and not getPlayerMask(varId) then
					if SendWanted:status() == 'running' or SendWanted:status() == 'yielded' then SendWanted:terminate() end
					SendWanted:run(string.format('/su %d %d %d.%d', varId, wanted[IM.Selc][i].star, IM.Selc, i))
				end

				if wanted[IM.Selc][i].text ~= 'nil' and wanted[IM.Selc][i].text ~= '' then
					Tooltip(('Ур.розыска: %d\nПримечание: %s'):format(wanted[IM.Selc][i].star, select(1, wanted[IM.Selc][i].text:gsub('\n', '\n'))))
				else
					Tooltip(('Ур.розыска: %d'):format(wanted[IM.Selc][i].star))
				end
			end
		end


		imgui.EndChild()
		if isRed then
			imgui.PushItemWidth(getFullHD(170))
			if imgui.Combo(u8'##Combo :: Статей', IM.cStat, items_stat, 5) then generate_items_pod() IM.cPods.v = 0 end
			imgui.PopItemWidth()
			imgui.SameLine(nil, getFullHD(5))
			imgui.PushItemWidth(getFullHD(358))
			imgui.Combo(u8'##Combo :: Подстатей', IM.cPods, items_pod, 5)
			imgui.PopItemWidth()
			imgui.PushItemWidth(getFullHD(170))
			imgui.PushAllowKeyboardFocus(false)
			imgui.InputText(u8'##Ввод :: Статей', IM.Buf1)
			imgui.PopAllowKeyboardFocus()
			imgui.PopItemWidth()
			if not imgui.IsItemActive() and #IM.Buf1.v == 0 then
				local text = u8'Название статьи'
				local item_size = imgui.GetItemRectSize()
				local text_size = imgui.CalcTextSize(text)
				imgui.SameLine(nil, 0)
				local item_pos = imgui.GetCursorPosX()
				imgui.SetCursorPosX(item_pos - (item_size.x + text_size.x) / 2)
				imgui.Text(text)
			end

			imgui.SameLine(isFullHD() and 270 or 183)
			imgui.PushItemWidth(getFullHD(358))
			imgui.PushAllowKeyboardFocus(false)
			imgui.InputText(u8'##Ввод :: Подстатей', IM.Buf2)
			imgui.PopAllowKeyboardFocus()
			imgui.PopItemWidth()
			if not imgui.IsItemActive() and #IM.Buf2.v == 0 then
				local text = u8'Название подстатьи'
				local item_size = imgui.GetItemRectSize()
				local text_size = imgui.CalcTextSize(text)
				imgui.SameLine(nil, 0)
				local item_pos = imgui.GetCursorPosX()
				imgui.SetCursorPosX(item_pos - (item_size.x + text_size.x) / 2)
				imgui.Text(text)
			end
			imgui.PushStyleVar(imgui.StyleVar.ButtonTextAlign, imgui.ImVec2(0.5, 0.5))
			if imgui.Button(u8'Добавить##1', imgui.ImVec2(getFullHD(83), 0)) then
				if IM.Buf1.v ~= '' and not wanted[IM.cStat.v+1] then
					wanted[IM.cStat.v+1] = {title = u8:decode(IM.Buf1.v)}
					generate_items_stat()
					generate_items_pod()
					IM.Buf1.v = ''
					save_wanted()
					addNotif('Добавлена статья:\n' .. wanted[IM.cStat.v+1].title, IM.float3.v)
				else
					addNotif('[Ошибка] Буффер пуст \\ статья существует', IM.float2.v)
				end
			end
			imgui.SameLine(nil, getFullHD(4))
			if imgui.Button(u8'Удалить##1', imgui.ImVec2(getFullHD(83), 0)) then
				if wanted[IM.cStat.v+1] then
					addNotif('Удалена статья:\n' .. wanted[IM.cStat.v+1].title, IM.float3.v)
					wanted[IM.cStat.v+1] = nil
					generate_items_stat()
					generate_items_pod()
					save_wanted()
				else
					addNotif('[Ошибка] Статьи не существует', IM.float2.v)
				end
			end
			imgui.PopStyleVar()
			imgui.SameLine(nil, getFullHD(5))
			imgui.PushItemWidth(getFullHD(140))
			imgui.PushAllowKeyboardFocus(false)
			imgui.InputText(u8'##Ввод :: Примечание', IM.Buf3)
			imgui.PopAllowKeyboardFocus()
			imgui.PopItemWidth()
			if not imgui.IsItemActive() and #IM.Buf3.v == 0 then
				local text = u8'Примечание'
				local item_size = imgui.GetItemRectSize()
				local text_size = imgui.CalcTextSize(text)
				imgui.SameLine(nil, 0)
				local item_pos = imgui.GetCursorPosX()
				imgui.SetCursorPosX(item_pos - (item_size.x + text_size.x) / 2)
				imgui.Text(text)
			end
			imgui.SameLine(isFullHD() and 487 or 327)
			imgui.PushItemWidth(getFullHD(39))
			imgui.PushStyleVar(imgui.StyleVar.FramePadding, imgui.ImVec2(7, 3))
			imgui.Combo(u8'##Combo :: Звезды', IM.cStar, items_star, 6)
			imgui.PopStyleVar()
			imgui.PopItemWidth()
			imgui.SameLine(nil, getFullHD(5))
			imgui.PushStyleVar(imgui.StyleVar.ButtonTextAlign, imgui.ImVec2(0.5, 0.5))
			if imgui.Button(u8'Добавить##2', imgui.ImVec2(getFullHD(83), 0)) then
				if IM.Buf2.v ~= '' and wanted[IM.cStat.v+1] and not wanted[IM.cStat.v+1][IM.cPods.v+1] then
					wanted[IM.cStat.v+1][IM.cPods.v+1] = {
						title = u8:decode(IM.Buf2.v);
						star = IM.cStar.v+1;
						text = u8:decode(IM.Buf3.v)
					}
					IM.Buf2.v = ''
					IM.Buf3.v = ''
					generate_items_pod()
					save_wanted()
					addNotif('Добавлена подстатья:\n' .. wanted[IM.cStat.v+1][IM.cPods.v+1].title, IM.float3.v)
				else
					addNotif('[Ошибка] Статьи не существует \\ подстатья существует \\ буффер пуст', IM.float2.v)
				end
			end
			imgui.SameLine(nil, getFullHD(4))
			if imgui.Button(u8'Удалить##2', imgui.ImVec2(getFullHD(83), 0)) then
				if wanted[IM.cStat.v+1] and wanted[IM.cStat.v+1][IM.cPods.v+1] then
					addNotif('Удалена подстатья:\n' .. wanted[IM.cStat.v+1][IM.cPods.v+1].title, IM.float3.v)
					wanted[IM.cStat.v+1][IM.cPods.v+1] = nil
					generate_items_pod()
					save_wanted()
				else
					addNotif('[Ошибка] Статьи не существует \\ подстатьи не существует', IM.float2.v)
				end
			end
			imgui.PopStyleVar()
		end
		imgui.End()
		imgui.PopFont()
	end
	if IM.Styl.v then
		imgui.PushFont(isFullHD() and font[19] or font[0])
		imgui.SetNextWindowSize(imgui.ImVec2(isFullHD() and 325 or 290, isFullHD() and 348 or 308), imgui.Cond.FirstUseEver)
	    imgui.SetNextWindowPos(imgui.ImVec2(ToScreen(100, 200)), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
	    imgui.Begin(u8'Редактор стиля', IM.Styl, imgui.WindowFlags.AlwaysVerticalScrollbar)

		imgui.PushStyleVar(imgui.StyleVar.ButtonTextAlign, imgui.ImVec2(0.5, 0.5))
		imgui.SetCursorPosX(5)
		if imgui.Button('REVERT ALL', imgui.ImVec2(imgui.GetContentRegionAvailWidth() + 3, 0)) then revert_colors() end
		imgui.PopStyleVar()
		if imgui.CollapsingHeader(u8('Цвета')) then
			for k, v in pairs(setTable) do

				if imgui.TreeNode(u8(k)) then
					for sk, sv in pairs(v) do
						local color = imgui.ImFloat4(imgui.ImColor(ini.colors[sk]):GetFloat4())
						imgui.AlignTextToFramePadding()
						imgui.Text(u8(sv))
						imgui.SameLine(195)
						if imgui.ColorEdit4(u8'##ColEdit' .. sk, color, imgui.ColorEditFlags.NoInputs + imgui.ColorEditFlags.NoLabel + imgui.ColorEditFlags.AlphaBar) then
							local newColor = imgui.ImColor.FromFloat4(color.v[1], color.v[2], color.v[3], color.v[4]):GetVec4()
							ini.colors[sk] = imgui.ImColor(newColor):GetU32()
							inicfg.save(ini, DIR_INI);
							colors[sk] = newColor
							if copColor[sk] then
								for _, iv in ipairs(copColor[sk]) do
									colors[iv] = newColor
								end
							end
						end
						if ini.colors[sk] ~= default_colors[sk] then
							imgui.SameLine(nil, 8)
							if imgui.Button('REVERT##' .. sk) then revert_colors(sk) end
						end
					end
					imgui.TreePop()
				end
			end
		end
		if imgui.CollapsingHeader(u8'Время уведомлений') then
			if imgui.SliderFloat(u8'Урон', IM.float1, 0.0, 10.0, '%.1f') then
				ini.float[1] = IM.float1.v; inicfg.save(ini, DIR_INI)
			end
			if imgui.SliderFloat(u8'Ошибка', IM.float2, 0.0, 10.0, '%.1f') then
				ini.float[2] = IM.float2.v; inicfg.save(ini, DIR_INI)
			end
			if imgui.SliderFloat(u8'Успешно', IM.float3, 0.0, 10.0, '%.1f') then
				ini.float[3] = IM.float3.v; inicfg.save(ini, DIR_INI)
			end
		end
		if imgui.CollapsingHeader(u8'Боекомплект') then
			for k, i in pairs(setAmmo) do
				if imgui.Checkbox(u8(i[1]), IM[i[2]]) then
					ini.ammo[i[2]] = IM[i[2]].v
					inicfg.save(ini, DIR_INI)
				end
			end
		end
		if imgui.CollapsingHeader(u8'Клавиши') then
			if imgui.Hotkey(u8'Выдать розыск', hotKey.wanted, 90) then
				nextLockKey = hotKey.wanted.v
				ini.key.wanted = hotKey.wanted.v
				inicfg.save(ini, DIR_INI)
			end
			if imgui.Hotkey(u8'Начать поногю', hotKey.pursuit, 90) then
				nextLockKey = hotKey.pursuit.v
				ini.key.pursuit = hotKey.pursuit.v
				inicfg.save(ini, DIR_INI)
			end
			if imgui.Hotkey(u8'Взять БК', hotKey.ammo, 90) then
				nextLockKey = hotKey.ammo.v
				ini.key.ammo = hotKey.ammo.v
				inicfg.save(ini, DIR_INI)
			end
		end
		imgui.Text(u8'Версия: '..thisScript().version)
		imgui.End()
		imgui.PopFont()
	end
	local notX, notY = ToScreen(isFullHD() and 475 or 445.5, 180)
	imgui.SetNextWindowSize(imgui.ImVec2(isFullHD() and 430 or 352, resY-notY-20), imgui.Cond.FirstUseEver)
	imgui.SetNextWindowPos(imgui.ImVec2(notX, notY), imgui.Cond.FirstUseEver, imgui.ImVec2(0.0, 0.0))
	imgui.PushStyleColor(imgui.Col.WindowBg, imgui.ImColor(0, 0, 0, 0):GetVec4())

	imgui.Begin('##notification :: Begin', _, imgui.WindowFlags.NoTitleBar + imgui.WindowFlags.NoMove + imgui.WindowFlags.NoScrollbar + imgui.WindowFlags.NoResize + imgui.WindowFlags.NoBringToFrontOnFocus + imgui.WindowFlags.NoFocusOnAppearing + imgui.WindowFlags.NoCollapse)
	imgui.PushFont(isFullHD() and font[23] or font[17])
	imgui.PushStyleVar(imgui.StyleVar.ItemSpacing, imgui.ImVec2(8, 4))
	imgui.PushStyleVar(imgui.StyleVar.ChildWindowRounding, 4)
	imgui.PushStyleVar(imgui.StyleVar.WindowPadding, imgui.ImVec2(7.0, 2.0))
	imgui.PushStyleColor(4, colors[43])
	imgui.PushStyleColor(8, colors[38])
	for i, v in ipairs(notif) do
		local size = imgui.GetFont():CalcTextSizeA(imgui.GetFont().FontSize, isFullHD() and 410 or 330.0, isFullHD() and 405 or 326.0, v.text)
		local _xmax = isFullHD() and 410 or 330
		local x = size.x > _xmax and _xmax or size.x + imgui.GetStyle().ItemSpacing.x
		local time = v.time - os.clock()
		if time > 0 then
			imgui.NewLine()
			imgui.SameLine(imgui.GetWindowWidth() - 6 - x - imgui.GetStyle().WindowPadding.x)
			imgui.BeginChild('##notification' .. i, imgui.ImVec2(x + 8, size.y + 8 + imgui.GetFontSize() * 0.5), false, imgui.WindowFlags.AlwaysUseWindowPadding + imgui.WindowFlags.NoScrollbar + imgui.WindowFlags.NoScrollWithMouse)
			imgui.TextWrapped(v.text)
			imgui.ProgressBar(time / v.kd, imgui.ImVec2(-1, 4), '')
			imgui.EndChild()
		else table.remove(notif, i)
		end
	end
	imgui.PopStyleColor(2)
	imgui.PopStyleVar(3)
	imgui.PopFont()
	imgui.End()
	imgui.PopStyleColor()
end

function addNotif(text, kd)
	if kd ~= 0 then
		table.insert(notif, {time = os.clock()+kd; kd=kd; text=u8(text)})
	end
end

function sampev.onSetPlayerAttachedObject(playerId, index, create, object)
	if index == 2 then
		if create then
			if isMasked(object.modelId) --[[and object.bone == 2]] then
				masked[playerId] = true;
			end
		else
			if masked[playerId] then
				masked[playerId] = nil
			end
		end
	end
	return true
end
function sampev.onPlayerStreamOut(playerId)
	if masked[playerId] then
		masked[playerId] = nil
	end
	return true
end
function sampev.onShowDialog(id, style, title, b1, b2, text)
	if id == 245 and title == 'Склад оружия' and style == 4 and isGetAmmo then
		if IM.deagle.v and getAmmoInCharWeapon(PLAYER_PED, 24) <= 21 then
			sampSendDialogResponse(id, 1, 0, nil) -- Deagle
			return false
		elseif IM.shotgun.v and getAmmoInCharWeapon(PLAYER_PED, 25) <= 30 then
			sampSendDialogResponse(id, 1, 1, nil) -- Shotgun
			return false
		elseif IM.smg.v and getAmmoInCharWeapon(PLAYER_PED, 29) <= 90 then
			sampSendDialogResponse(id, 1, 2, nil) -- SMG
			return false
		elseif IM.m4.v and getAmmoInCharWeapon(PLAYER_PED, 31) <= 150 then
			sampSendDialogResponse(id, 1, 3, nil) -- M4
			return false
		elseif IM.rifle.v and getAmmoInCharWeapon(PLAYER_PED, 33) <= 30 then
			sampSendDialogResponse(id, 1, 4, nil) -- Rifle
			return false
		elseif IM.armour.v then
			if getCharArmour(PLAYER_PED) < 100 or (getCharHealth(PLAYER_PED) < 100) or (sampTextdrawIsExists(2048) and tonumber(sampTextdrawGetString(2048)) < 20) then
				sampSendDialogResponse(id, 1, 5, nil) -- Armour
				return false
			end
		elseif IM.granate.v then
			if (getAmmoInCharWeapon(PLAYER_PED, 3) < 1) or (getAmmoInCharWeapon(PLAYER_PED, 17) > 0 and getAmmoInCharWeapon(PLAYER_PED, 17) <= 10) then
				sampSendDialogResponse(id, 1, 6, nil) -- Granate
				return false
			end
		end
	end
end

function getFullHD(size)
	if resX == 1920 then
		return size * 1.5
	else
		return size
	end
end
function isFullHD()
	return resX == 1920
end
function getPlayerMask(id)
	return sampGetPlayerColor(id) == 2855811128 and masked[id]
end
-- # MASK # [18911, 18912, 18913, 18914, 18915, 18916, 18917, 18918, 18919, 18920, 19036, 19037, 19038, 18974, 19085]
function isMasked(id)
	if (id >= 18911 and id <= 18920) or (id >= 19036 and id <= 19038) or id == 19085 or id == 18974 then return true else return false end
end
function save_wanted()
	local file = io.open(DIR_WANTED, 'w')
	file:write(wanted_tostring(wanted))
	file:flush()
	io.close(file)
end

function wanted_tostring(t)
	local result = 'return {\n';
	for i = 1, IM.mStat do
		if t[i] then
			local title = t[i].title:gsub('\n', '')
			result = result .. string.format('\t[%d] = {\n\t\ttitle = \'%s\';\n', i, title);
			for o = 1, IM.mPods do
				if t[i][o] then
					local title = t[i][o].title:gsub('\n', '')
					local text  = t[i][o].text:gsub('\n', '\\\\n')
					result = result .. string.format('\t\t[%d] = {\n\t\t\ttitle = \'%s\';\n\t\t\tstar = %d;\n\t\t\ttext = \'%s\';\n\t\t};\n', o, title, t[i][o].star, text or '');
				end
			end
			result = result .. '\t};\n'
		end
	end
	result = result .. '}'
	return result
end

function generate_items_stat()
	local t = {}
	for i = 1, IM.mStat do
		if wanted[i] then
			table.insert(t, u8(string.format('[%d] %s', i, wanted[i].title)))
		else
			table.insert(t, u8(string.format('[%d] Пусто', i)))
		end
	end
	items_stat = t
end
function generate_items_pod()
	local t = {}
	if wanted[IM.cStat.v+1] then
		for i = 1, IM.mPods do
			if wanted[IM.cStat.v+1][i] then
				table.insert(t, u8(string.format('[%d.%d] %s', IM.cStat.v+1, i, wanted[IM.cStat.v+1][i].title)))
			else
				table.insert(t, u8(string.format('[%d.%d] Пусто', IM.cStat.v+1, i)))
			end
		end
	else
		table.insert(t, u8(string.format('[%d] Отсутствует статья', IM.cStat.v+1)))
		IM.cPods.v = 0
	end
	items_pod = t
end

function load_wanted()
	local f = io.open(DIR_WANTED, 'r')
	local func = load(f:read('*a'))
    local data = select(2, pcall(func))
	f:close()
	wanted = data
end

function Tooltip(text)
    if imgui.IsItemHovered() then
        imgui.BeginTooltip()
        imgui.PushTextWrapPos(350.0)
        imgui.TextUnformatted(u8(text))
        imgui.PopTextWrapPos()
        imgui.EndTooltip()
    end
end

function onScriptTerminate(scr, quitGame)
	if scr == script.this then
		imgui.Process = false
		if mouse then showCursor(false, false) end
	end
end

function revert_colors(index)
	if index then
		ini.colors[index] = default_colors[index]
		colors[index] = imgui.ImColor(default_colors[index]):GetVec4()
	else
		for k, v in pairs(default_colors) do
			ini.colors[k] = v
			colors[k] = imgui.ImColor(v):GetVec4()
		end
	end
	inicfg.save(ini, DIR_INI);
	for k, v in pairs(copColor) do
		for _, iv in ipairs(copColor[k]) do
			colors[iv] = colors[k]
		end
	end
end

function apply_custom_style()
	local style = imgui.GetStyle()
	local colors = style.Colors
	local clr = imgui.Col
	local ImVec4 = imgui.ImVec4

	style.WindowTitleAlign  = imgui.ImVec2(0.5, 0.5)
	style.ScrollbarSize     = 13.0
	style.ScrollbarRounding = 0
	style.GrabMinSize       = 8.0
	style.GrabRounding      = 1.0
	style.ButtonTextAlign   = imgui.ImVec2(0, 0.5)
	colors[clr.TextDisabled]           = ImVec4(0.50, 0.50, 0.50, 1.00)
	colors[clr.ChildWindowBg]          = ImVec4(0.00, 0.00, 0.00, 0.00)
	colors[clr.BorderShadow]           = ImVec4(0.00, 0.00, 0.00, 0.00)
	colors[clr.TitleBgCollapsed]       = ImVec4(0.05, 0.05, 0.05, 0.79)
	colors[clr.MenuBarBg]              = ImVec4(0.14, 0.14, 0.14, 1.00)
	colors[clr.CheckMark]              = ImVec4(1.00, 1.00, 1.00, 1.00)
	colors[clr.SliderGrab]             = ImVec4(0.28, 0.28, 0.28, 1.00)
	colors[clr.SliderGrabActive]       = ImVec4(0.35, 0.35, 0.35, 1.00)
	colors[clr.SeparatorHovered]       = ImVec4(0.26, 0.59, 0.98, 0.78)
	colors[clr.SeparatorActive]        = ImVec4(0.26, 0.59, 0.98, 1.00)
	colors[clr.ResizeGrip]             = ImVec4(0.26, 0.59, 0.98, 0.25)
	colors[clr.ResizeGripHovered]      = ImVec4(0.26, 0.59, 0.98, 0.67)
	colors[clr.ResizeGripActive]       = ImVec4(0.26, 0.59, 0.98, 0.95)
	colors[clr.CloseButton]            = ImVec4(0.41, 0.41, 0.41, 0.50)
	colors[clr.CloseButtonHovered]     = ImVec4(0.98, 0.39, 0.36, 1.00)
	colors[clr.CloseButtonActive]      = ImVec4(0.98, 0.39, 0.36, 1.00)
	colors[clr.TextSelectedBg]         = ImVec4(0.26, 0.59, 0.98, 0.35)
end
apply_custom_style()



function getDownKeys()
    local curkeys = ""
    local bool = false
    for k, v in pairs(vkeys) do
        if isKeyDown(v) and (v == VK_MENU or v == VK_CONTROL or v == VK_SHIFT or v == VK_LMENU or v == VK_RMENU or v == VK_RCONTROL or v == VK_LCONTROL or v == VK_LSHIFT or v == VK_RSHIFT) then
            if v ~= VK_MENU and v ~= VK_CONTROL and v ~= VK_SHIFT then
                curkeys = v
            end
        end
    end
    for k, v in pairs(vkeys) do
        if isKeyDown(v) and (v ~= VK_MENU and v ~= VK_CONTROL and v ~= VK_SHIFT and v ~= VK_LMENU and v ~= VK_RMENU and v ~= VK_RCONTROL and v ~= VK_LCONTROL and v ~= VK_LSHIFT and v ~= VK_RSHIFT) then
            if tostring(curkeys):len() == 0 then
                curkeys = v
            else
                curkeys = curkeys .. ' ' .. v
            end
            bool = true
        end
    end
    return curkeys, bool
end
function isKeysDown(keylist, pressed)
    local tKeys = string.split(keylist, ' ')
    if pressed == nil then
        pressed = false
    end
    if tKeys[1] == nil then
        return false
    end
    local bool = false
    local key = #tKeys < 2 and tonumber(tKeys[1]) or tonumber(tKeys[2])
    local modified = tonumber(tKeys[1])
    if #tKeys < 2 then
        if not isKeyDown(VK_RMENU) and not isKeyDown(VK_LMENU) and not isKeyDown(VK_LSHIFT) and not isKeyDown(VK_RSHIFT) and not isKeyDown(VK_LCONTROL) and not isKeyDown(VK_RCONTROL) then
            if wasKeyPressed(key) and not pressed then
                bool = true
            elseif isKeyDown(key) and pressed then
                bool = true
            end
        end
    else
        if isKeyDown(modified) and not wasKeyReleased(modified) then
            if wasKeyPressed(key) and not pressed then
                bool = true
            elseif isKeyDown(key) and pressed then
                bool = true
            end
        end
    end
    if nextLockKey == keylist then
        if pressed and not wasKeyReleased(key) then
            bool = false
        else
            bool = false
            nextLockKey = ''
        end
    end
    return bool
end
function string.split(inputstr, sep)
	sep = sep or '%s'
    local t={} ; i=1
    for str in string.gmatch(inputstr, '([^'..sep..']+)') do
    	t[i] = str
        i = i + 1
    end
    return t
end

function imgui.Hotkey(name, keyBuf, width)
    local name = tostring(name)
    local keys, endkey = getDownKeys()
    local keysName = ''
    local ImVec2 = imgui.ImVec2
    local bool = false
    if editHotkey == name then
        if keys == VK_BACK then
            keyBuf.v = ''
            editHotkey = nil
            nextLockKey = keys
            editKeys = 0
        else
            local tNames = string.split(keys, ' ')
            local keylist = ''
            for _, v in ipairs(tNames) do
                local key = tostring(vkeys.id_to_name(tonumber(v)))
                if tostring(keylist):len() == 0 then
                    keylist = key
                else
                    keylist = keylist .. ' + ' .. key
                end
            end
            keysName = keylist
            if endkey then
                bool = true
                keyBuf.v = tostring(keys)
                editHotkey = nil
                nextLockKey = keys
                editKeys = 0
            end
        end
    else
        local tNames = string.split(keyBuf.v, ' ')
        for _, v in ipairs(tNames) do
            local key = tostring(vkeys.id_to_name(tonumber(v)))
            if tostring(keysName):len() == 0 then
                keysName = key
            else
                keysName = keysName .. ' + ' .. key
            end
        end
    end
    local style = imgui.GetStyle()
    local colors = style.Colors
    local clr = imgui.Col
    imgui.PushStyleColor(imgui.Col.Button, colors[clr.FrameBg])
    imgui.PushStyleColor(imgui.Col.ButtonActive, colors[clr.FrameBg])
    imgui.PushStyleColor(imgui.Col.ButtonHovered, colors[clr.FrameBg])
    imgui.PushStyleVar(imgui.StyleVar.ButtonTextAlign, ImVec2(0.04, 0.5))
    imgui.Button(u8((tostring(keysName):len() > 0 or editHotkey == name) and keysName or 'Нет'), ImVec2(width, 20))
    imgui.PopStyleVar()
    imgui.PopStyleColor(3)
    if imgui.IsItemHovered() and imgui.IsItemClicked() and editHotkey == nil then
        editHotkey = name
        editKeys = 100
    end
    if name:len() > 0 then
        imgui.SameLine()
        imgui.Text(name)
    end
    return bool
end
function onWindowMessage(msg, wparam, lparam)
    if (msg == 0x100 or msg == 0x101) then
        if (wparam == VK_ESCAPE or wparam == VK_RETURN or wparam == VK_TAB or wparam == VK_F6 or wparam == VK_F7 or wparam == VK_F8 or wparam == VK_T or wparam == VK_OEM_3) and msg == 0x100 and editKeys > 0 then
            consumeWindowMessage(true, true)
            editHotkey = nil
       end
    end
end
function sampev.onSendChat(message) antiflood = os.clock() * 1000 end
function sampev.onSendCommand(cmd)  antiflood = os.clock() * 1000
	local command = {};
    for match in string.gmatch(cmd..' ', '(.-) ') do
        table.insert(command, match);
    end
	if command[1] == '/su' and #command == 2 then
		isRed = false
		varId = tonumber(command[2]) or -1
		IM.Want.v = true
		return false
	end
	if command[1] == '/redw' and #command == 1 then
		varId = -1
		if IM.Want.v and isRed then
			IM.Want.v = false
		else
			IM.Want.v, isRed = true, true
		end
		return false
	end -- getPlayerMask(id)
	if command[1] == '/reds' and #command == 1 then
		varId = -1
		-- if IM.Want.v then IM.Want.v = false end
		IM.Styl.v = not IM.Styl.v
		return false
	end
end

function autoupdate(json_url, url)
	local update = true
	local updatestatus
	local json = getWorkingDirectory() .. '\\'..thisScript().name..'-version.json'
	if doesFileExist(json) then os.remove(json) end
		downloadUrlToFile(json_url, json,
		function(id, status, p1, p2)
			if status == dlstatus.STATUSEX_ENDDOWNLOAD then
				if doesFileExist(json) then
					local f = io.open(json, 'r')
					if f then
						local info = decodeJson(f:read('*a'))
						f:close()
						os.remove(json)
						if info.latest ~= thisScript().version then
							lua_thread.create(function(link, ver)
								sampAddChatMessage('Обнаружено обновление. Пытаюсь обновиться c '..thisScript().version..' на '..ver, 0xEBEBEB)
								wait(250)
								downloadUrlToFile(link, thisScript().path,
								function(id, status, p1, p2)
									if status == dlstatus.STATUS_DOWNLOADINGDATA then
										print(string.format('Загружено %d из %d.', p1, p2))
									elseif status == dlstatus.STATUS_ENDDOWNLOADDATA then
										print('Загрузка обновления завершена.')
										sampAddChatMessage('Обновление завершено!', 0xEBEBEB)
										goupdatestatus = true
										lua_thread.create(function()
											wait(500)
											thisScript():reload()
										end)
									end
									if status == dlstatus.STATUSEX_ENDDOWNLOAD then
										if goupdatestatus == nil then
											sampAddChatMessage('Обновление прошло неудачно. Запускаю устаревшую версию..', 0xEBEBEB)
											update = false
										end
									end
								end)
							end, info.updateurl, info.latest)
						else
							update = false
							print('Обновление не требуется.')
						end
					end
				else
					print('Не могу проверить обновление. Смиритесь или просите у '.. url)
					update = false
				end
			end
		end)
	while update ~= false do wait(100) end
end
function chat_cont()
	return not sampIsChatInputActive() and not isSampfuncsConsoleActive()
end
