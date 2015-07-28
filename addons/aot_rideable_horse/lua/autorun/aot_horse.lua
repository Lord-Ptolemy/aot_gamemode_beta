if CLIENT then
	print("Loaded Clientside Callbacks")
	local AOT_Horse_Hud_Control = true
	local AOT_Horse_Hud_KeyReleased = false
	local AOT_Horse_Hud_ShowControls = false
	local AOT_Horse_Hud_Speed = 0
	
	net.Receive("horseragdoll", function (len)
		util.PrecacheModel("models/horse.mdl")
		local ragdoll = ClientsideRagdoll("models/horse.mdl")
		ragdoll:SetPos(net.ReadVector())
		ragdoll:SetNoDraw( false )
		ragdoll:DrawShadow( true )
		ragdoll:Spawn()
	end)
	
	net.Receive("AOT_Horse_HUD_Control", function (len)
		AOT_Horse_Hud_ShowControls = net.ReadBool()
	end)
	
	net.Receive("AOT_Horse_HUD_Control_Speed", function (len)
		AOT_Horse_Hud_Speed = net.ReadInt(4)
	end)
	
	surface.CreateFont( "BrownZHorseControlsText", {
		font = "Arial",
		size = 20,
		weight = 500,
		blursize = 0,
		scanlines = 0,
		antialias = true,
		underline = false,
		italic = false,
		strikeout = false,
		symbol = false,
		rotary = false,
		shadow = false,
		additive = false,
		outline = false,
	} )
	
	hook.Add("HUDPaint", "HUDPaint_Horse_Controls", function()
		if AOT_Horse_Hud_ShowControls == true then
			if input.IsKeyDown(KEY_BACKSLASH) and AOT_Horse_Hud_KeyReleased == true then
				AOT_Horse_Hud_Control = not AOT_Horse_Hud_Control
				AOT_Horse_Hud_KeyReleased = false
			elseif not input.IsKeyDown(KEY_BACKSLASH) and AOT_Horse_Hud_KeyReleased == false then
				AOT_Horse_Hud_KeyReleased = true
			end
		end
		
		if AOT_Horse_Hud_ShowControls == true and AOT_Horse_Hud_Control == true then
			local AOT_Horse_Hud_Size = {}
			AOT_Horse_Hud_Size.x, AOT_Horse_Hud_Size.y = 300, 275
			local AOT_Horse_Hud_Pos = {}
			AOT_Horse_Hud_Pos.x, AOT_Horse_Hud_Pos.y = ScrW() - AOT_Horse_Hud_Size.x, ScrH()- AOT_Horse_Hud_Size.y
			
			draw.RoundedBox( 15, AOT_Horse_Hud_Pos.x, AOT_Horse_Hud_Pos.y, AOT_Horse_Hud_Size.x, AOT_Horse_Hud_Size.y, Color( 0, 0, 0, 128 ) )
			
			local HorseHudKeyTable = {}
			HorseHudKeyTable["speed"] = input.LookupBinding("+speed") or "UNBINDED"
			HorseHudKeyTable["moveleft"] = input.LookupBinding("+moveleft") or "UNBINDED"
			HorseHudKeyTable["moveright"] = input.LookupBinding("+moveright") or "UNBINDED"
			HorseHudKeyTable["walk"] = input.LookupBinding("+walk") or "UNBINDED"
			HorseHudKeyTable["back"] = input.LookupBinding("+back") or "UNBINDED"
			HorseHudKeyTable["jump"] = input.LookupBinding("+jump") or "UNBINDED"
			
			for k,v in pairs(HorseHudKeyTable) do
				HorseHudKeyTable[k] = string.upper(v)
			end
			
			local HorseHudStringTable = { 
			"Gait (Speed): VALUE",
			"Controls:",
			"Change Gait - (" .. HorseHudKeyTable["speed"] .. ")",
			"Stop Moving - (" .. HorseHudKeyTable["walk"].. ")",
			"Go Left - (" .. HorseHudKeyTable["moveleft"] .. ")",
			"Go Right - (" .. HorseHudKeyTable["moveright"] .. ")",
			"Back Up - (" .. HorseHudKeyTable["back"] .. ")",
			"Dismount - (" .. HorseHudKeyTable["jump"] .. ")",
			"Hide Controls - (BACKSLASH)"}
			
			if	AOT_Horse_Hud_Speed == 1 then 
				HorseHudStringTable[1] = string.Replace(HorseHudStringTable[1], "VALUE", "Walking")
			elseif	AOT_Horse_Hud_Speed == 2 then 
				HorseHudStringTable[1] = string.Replace(HorseHudStringTable[1], "VALUE", "Trotting")
			elseif	AOT_Horse_Hud_Speed == 3 then 
				HorseHudStringTable[1] = string.Replace(HorseHudStringTable[1], "VALUE", "Cantering")
			elseif 	AOT_Horse_Hud_Speed == 4 then 
				HorseHudStringTable[1] = string.Replace(HorseHudStringTable[1], "VALUE", "Galloping")
			elseif	AOT_Horse_Hud_Speed == 0 then 
				HorseHudStringTable[1] = string.Replace(HorseHudStringTable[1], "VALUE", "Stopped")
			end
			
			local HorseHudStartPosY = 10
			for k,v in pairs(HorseHudStringTable) do
				if k == 2 then HorseHudStartPosY = HorseHudStartPosY + 10 end
				draw.SimpleText (v, "BrownZHorseControlsText", AOT_Horse_Hud_Pos.x + (AOT_Horse_Hud_Size.x/2), AOT_Horse_Hud_Pos.y + (HorseHudStartPosY + (k*25)), Color(255,255,255,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
			end
		end
	end )
end