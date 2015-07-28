--[[
	Attack On Titan Ridable Horse
--]]
util.AddNetworkString("horseragdoll")
util.AddNetworkString("AOT_Horse_HUD_Control")
util.AddNetworkString("AOT_Horse_HUD_Control_Speed")
ENT.Base = "base_nextbot"
ENT.Spawnable = true
ENT.AdminSpawnable = true
ENT.Category = "Horse"
ENT.WalkSpeed = 6.4 			-- Kilometers per Hour						-- figure for average horse
ENT.TrotSpeed = 16 				-- Kilometers per Hour						-- figure for average horse
ENT.CanterSpeed = 21.5 			-- Kilometers per Hour						-- figure for average horse
ENT.GallopSpeed = 44 			-- Kilometers per Hour						-- figure for average horse
ENT.Acceleration = 12.96875 	-- Kilometers per Hour per Second			-- figure for thoroughbred racehorse
ENT.Deceleration = 968/36 		-- Negative Kilometers per Hour per Second	-- this deceleration rate is an estimate fix this later
ENT.SpookLevel = 0				-- percent spooked							-- varies in decimal amount from 0 to 1
ENT.SpeedSetting = 0
ENT.SightRange = 10000

ENT.SpeedDebounce = 0

local horsespook = {}
horsespook[1] = Sound("sounds/horse_whinny0.wav")
horsespook[2] = Sound("sounds/horse_whinny1.wav")
horsespook[3] = Sound("sounds/horse_whinny2.wav")

local horseidle = {}
horseidle[1] = Sound("sounds/horse_idle1.wav")
horseidle[2] = Sound("sounds/horse_idle2.wav")
horseidle[3] = Sound("sounds/horse_idle3.wav")
horseidle[4] = Sound("sounds/horse_idle4.wav")

local horsewalk = {}
horsewalk[1] = Sound("sounds/horse_walking01.wav")
horsewalk[2] = Sound("sounds/horse_walking02.wav")
horsewalk[3] = Sound("sounds/horse_walking03.wav")
horsewalk[4] = Sound("sounds/horse_walking04.wav")
horsewalk[5] = Sound("sounds/horse_walking05.wav")
horsewalk[6] = Sound("sounds/horse_walking06.wav")

local horserun = {}
horserun[1] = Sound("sounds/horse_running01.wav")
horserun[2] = Sound("sounds/horse_running02.wav")
horserun[3] = Sound("sounds/horse_running03.wav")
horserun[4] = Sound("sounds/horse_running04.wav")
horserun[5] = Sound("sounds/horse_running05.wav")
horserun[6] = Sound("sounds/horse_running06.wav")

local mode = gmod.GetGamemode()
mode.OldCanPlayerEnterVehicle = mode.OldCanPlayerEnterVehicle or mode.CanPlayerEnterVehicle 
mode.OldCanExitVehicle = mode.OldCanExitVehicle or mode.CanExitVehicle 
function mode:CanPlayerEnterVehicle( ply, vehicle, unk )
	if(vehicle:GetOwner() and IsValid(vehicle:GetOwner()) and vehicle:GetOwner():GetClass() == "aot_rideable_horse" ) then
		return true
	else
		return mode:OldCanPlayerEnterVehicle( ply, vehicle, unk )
	end
end

function mode:CanExitVehicle(veh,ply)
	if veh:GetOwner() and IsValid(veh:GetOwner()) and veh:GetOwner():GetClass() == "aot_rideable_horse" then
		return false
	else
		return mode:OldCanExitVehicle(veh,ply)
	end
end

function ENT:Initialize()
	print("Spawned a horse")
	self:SetModel("models/horse.mdl")
	self:SetHealth(300)
	self:SetMaxHealth(300)
	self:PhysicsInitShadow(true, true)
/*	if system.IsOSX() then
		if CLIENT then 
			LocalPlayer():PrintMessage(HUD_PRINTTALK,"Get a PC Dumbass!")
			LocalPlayer():PrintMessage(HUD_PRINTCENTER,"Get a PC Dumbass!")
		else
			PrintMessage(HUD_PRINTTALK,"Get a PC Dumbass!")
			PrintMessage(HUD_PRINTCENTER,"Get a PC Dumbass!")
		end
	end */
	local this = self
	local bone = self:LookupBone("SK_spine_2")
	local mount = self:LookupAttachment("mount")
	local attachment_offset = Vector(0, 0, 8)
	
	self.Saddle = ents.Create("prop_vehicle_prisoner_pod")
	self.Saddle:SetModel("models/nova/airboat_seat.mdl")
	self.Saddle:SetNoDraw(true)
	self.Saddle:SetKeyValue("vehiclescript", "scripts/vehicles/prisoner_pod.txt")
	self.Saddle:SetKeyValue("limitview", "0")
	self.Saddle:SetKeyValue("VehicleLocked", "1")
	self.Saddle.HandleAnimation = function( vehicle, player ) player:SelectWeightedSequence( ACT_DRIVE_AIRBOAT ) end
	self.Saddle:SetPos(self:GetBonePosition(bone)+attachment_offset)
	self.Saddle:SetAngles(self:GetBoneMatrix(bone):GetAngles()+Angle(0,-90,-90))
	
	self.Saddle:Spawn()
	self.Saddle:SetOwner(self)
	self.Saddle:SetParent(self,mount)
	self.Saddle:SetCollisionGroup(COLLISION_GROUP_NONE)
	self.Saddle:SetSolid(SOLID_NONE)
	
	function self.Saddle:Use( activator, caller, use_type, value)
		this:Use( activator, caller, use_type, value)
	end
	self.AIThread = coroutine.create( function()
		while (true) do 
			self:AIThink()
			coroutine.yield()
		end
	end )
	self.headBone = self:LookupBone("SK_head")
end

function ENT:ToggleControls(ply, bool)
	net.Start("AOT_Horse_HUD_Control")
		net.WriteBool( bool )
	net.Send(ply)
end

function ENT:SendSpeed(ply,speed)
	net.Start("AOT_Horse_HUD_Control_Speed")
		net.WriteInt( speed, 4 )
	net.Send(ply)
end

function ENT:SaddleThink()
	if not self.Saddle:GetDriver() or not IsValid(self.Saddle:GetDriver()) then
		---[[ enable this code if collision mounting and use mounting don't work
		local players = player.GetAll()
		local distance = 32
		local newdriver = nil
		for i=1,#players do
			if players[i] and IsValid(players[i]) then
				local dist = (players[i]:GetPos()-self.Saddle:GetPos()):Length2D()
				if dist < distance and players[i]:Alive() and not players[i]:InVehicle() and players[i]:Team() != TEAM_TITAN_N then
					local weapon = players[i]:GetActiveWeapon()
					local left = weapon:GetVar("leftanker") and weapon.left:GetNetworkedBool("Colide")
					local right = weapon:GetVar("rightanker") and weapon.right:GetNetworkedBool("Colide")
					local basic = weapon:GetVar("anker") and weapon.Main:GetNetworkedBool("Colide")
					if not left and not right and not basic then
						distance = dist
						newdriver = players[i]
					end
				end
			end
		end
		if newdriver then
			newdriver:SetAllowWeaponsInVehicle(true)
			newdriver:EnterVehicle(self.Saddle)
			self.Saddle:SetCameraDistance(128)
			self:ToggleControls(newdriver,true)
		end
		self.LastDriverCheck = CurTime()
		--]]
	elseif self.Saddle:GetDriver() and IsValid(self.Saddle:GetDriver())  then
		local driver = self.Saddle:GetDriver()
		local weapon = driver:GetActiveWeapon()
		if weapon and IsValid(weapon) then
			local left = weapon:GetVar("leftanker") and weapon.left:GetNetworkedBool("Colide")
			local right = weapon:GetVar("rightanker") and weapon.right:GetNetworkedBool("Colide")
			local basic = weapon:GetVar("anker") and weapon.Main:GetNetworkedBool("Colide")
			if left or right or basic then
				driver:ExitVehicle()
				self:ToggleControls(driver,false)
			end
		end
	end
end

function ENT:MoveToPos( pos, options )

	local options = options or {}

	local path = Path( "Follow" )
	path:SetMinLookAheadDistance( options.lookahead or 300 )
	path:SetGoalTolerance( options.tolerance or 20 )
	path:Compute( self, pos )

	if ( !path:IsValid() ) then return "failed" end

	while ( path:IsValid() and not (self.Saddle:GetDriver() and IsValid(self.Saddle:GetDriver())) ) do

		path:Update( self )

		-- Draw the path (only visible on listen servers or single player)
		if ( options.draw ) then
			path:Draw()
		end

		-- If we're stuck then call the HandleStuck function and abandon
		if ( self.loco:IsStuck() ) then

			self:HandleStuck();
			
			return "stuck"

		end

		--
		-- If they set maxage on options then make sure the path is younger than it
		--
		if ( options.maxage ) then
			if ( path:GetAge() > options.maxage ) then return "timeout" end
		end

		--
		-- If they set repath then rebuild the path every x seconds
		--
		if ( options.repath ) then
			if ( path:GetAge() > options.repath ) then path:Compute( self, pos ) end
		end

		coroutine.yield()

	end

	return "ok"

end

function ENT:ConvertKpHtoUpS( speed )
	local kph_to_ips = 10.936132983
	local units_per_inch = 4/3
	return ((speed*kph_to_ips)*units_per_inch)
end

function ENT:ConvertKpHtoUpT( speed )
	local seconds_per_tick = engine.TickInterval()
	return self:ConvertKpHtoUpS( speed )*seconds_per_tick
end

function ENT:ConvertKpHpStoUpSpS( acceleration )
	return self:ConvertKpHtoUpS( acceleration )
end

function ENT:ConvertKpHpStoUpTpT( acceleration )
	local seconds_per_tick = engine.TickInterval()
	return (self:ConvertKpHpStoUpSpS(acceleration)*seconds_per_tick)*seconds_per_tick
end

function ENT:TableConcat(t1,t2)
    for i=1,#t2 do
        t1[#t1+1] = t2[i]
    end
    return t1
end

function ENT:FaceDirectionOfTravel()
	local speed = self.loco:GetVelocity():Length()
	if (speed > 0) and (not self.Back and (self.loco:GetVelocity():GetNormalized()+self:GetForward()):Length()>1)  then
		self.loco:FaceTowards(self:GetPos()+self.loco:GetVelocity())
	elseif (speed > 0) then
		self.loco:FaceTowards(self:GetPos()+self:GetForward())
	end
end

function ENT:Sight()
	local headpos = self:GetBonePosition(self.headBone)
	
	self.Entities = ents.FindInCone( headpos, self:GetRight(), self.SightRange, 90)
	self:TableConcat(self.Entities,ents.FindInCone( headpos, -self:GetRight(), self.SightRange, 90))
	self.LastLooked = CurTime()
end

function ENT:SpookMultiplier()
	local spook_avg = 0
	local spook_count = 0
	for i = 1,#self.Entities do
		if self.Entities[i] != self and self.Entities[i]:IsPlayer() then
			spook_count = spook_count + 1
			local spook = math.abs(((self.Entities[i]:GetVelocity():Length()/self.Entities[i]:Team())*self.SightRange-(self.Entities[i]:GetPos() - self:GetPos()):Length())/self.SightRange) * 2/self.Entities[i]:Team()
			spook_avg = spook_avg + spook
		end
	end
	
	spook_avg = spook_avg/spook_count
	
	self.SpookLevel = self.SpookLevel * spook_avg 
	if self.SpookLevel == 0 then self.SpookLevel = 0.001 end
	self.LastSpookCheck = CurTime()
end

function ENT:SelectAct()
	local speed = self.loco:GetVelocity():Length()
	if speed > self:ConvertKpHtoUpS((self.WalkSpeed*2+self.TrotSpeed+self.CanterSpeed+self.GallopSpeed)/5) then
		return ACT_RUN
	elseif speed > 0 then
		return ACT_WALK
	else
		self:SetPoseParameter("move_yaw",0)
		return ACT_IDLE
	end
end

function ENT:AIThink()
	self:Sight()
	coroutine.wait(0.1)
	self:SpookMultiplier()
	coroutine.wait(0.1)
	self:SaddleThink()
end

function ENT:Think()
	local activity = self:SelectAct()
	if self:GetActivity() != activity then
		self:StartActivity(activity)
	end
	
	local v = 0
	if self.Saddle and IsValid(self.Saddle) and self.Saddle:GetDriver() and IsValid(self.Saddle:GetDriver())then
		local driver = self.Saddle:GetDriver()
		if driver:KeyDown(IN_MOVELEFT) then
			self.Left = true
		else
			self.Left = false
		end
		if driver:KeyDown(IN_MOVERIGHT) then
			self.Right = true
		else
			self.Right = false
		end
		if driver:KeyPressed(IN_WALK) then
			self.SpeedSetting = 0
			self:SendSpeed(driver, self.SpeedSetting)
			if self.SpeedDebounce > 0 then
				self.SpeedDebounce = self.SpeedDebounce - 1
			end
		elseif driver:KeyPressed(IN_SPEED) and self.SpeedDebounce == 0 then
			self.SpeedDebounce = 2
			self.SpeedSetting = self.SpeedSetting + 1
			if self.SpeedSetting > 4 then self.SpeedSetting = 0 end
			self:SendSpeed(driver, self.SpeedSetting)
		elseif self.SpeedDebounce > 0 then
			self.SpeedDebounce = self.SpeedDebounce - 1
		end
		
		if driver:KeyPressed(IN_JUMP) then
			driver:ExitVehicle()
			self:ToggleControls(driver,false)
		end
		
		v = self.SpeedSetting or 1
		
		if (driver:KeyDown(IN_BACK)) then
			v = 1
			self.Back = true
		else
			self.Back = false
		end
	else 
		self.SpeedSetting = 0
		v = math.min(math.Truncate(self.SpookLevel * 3, 0),3) + 1
	end
	
	if		v == 1 then 
		self.Stop = false
		self.loco:SetDesiredSpeed( self:ConvertKpHtoUpS(self.WalkSpeed) )
	elseif	v == 2 then 
		self.Stop = false
		self.loco:SetDesiredSpeed( self:ConvertKpHtoUpS(self.TrotSpeed) )
	elseif	v == 3 then 
		self.Stop = false
		self.loco:SetDesiredSpeed( self:ConvertKpHtoUpS(self.CanterSpeed) )
	elseif 	v == 4 then 
		self.Stop = false
		self.loco:SetDesiredSpeed( self:ConvertKpHtoUpS(self.GallopSpeed) )
	elseif	v == 0 then 
		self.Stop = true
	end
	
	self:FaceDirectionOfTravel()
	
	if( coroutine.status(self.AIThread) == "suspended") then
		coroutine.resume(self.AIThread)
	end
end

function ENT:RunBehaviour()
	self.loco:SetAcceleration( self:ConvertKpHpStoUpSpS(self.Acceleration) )
	self.loco:SetDeceleration( self:ConvertKpHpStoUpSpS(self.Deceleration) )
	while ( true ) do
		---[[
		if(self.Saddle and IsValid(self.Saddle) and self.Saddle:GetDriver() and IsValid(self.Saddle:GetDriver())) then
			local driver = self.Saddle:GetDriver()
			local v = self:GetForward()
			if self.Back then
				v = -v
			end
			if self.Left then 
				v = v-self:GetRight()*15000/self.loco:GetVelocity():Length()
			end
			if self.Right then
				v = v+self:GetRight()*15000/self.loco:GetVelocity():Length()
			end
			v:Normalize()
			v = v + self:GetPos()
			if not self.Stop then
				if util.IsInWorld( v ) then
					self.LastVec = v
					self.loco:Approach( v, 0.000000000000001 )
				end
				coroutine.wait(0.01)
			else
				--self:PlaySequenceAndWait("idle")
				coroutine.wait(0.01)
			end
		else
			local vec = Vector(0,0,0)
			local averagecount = 0
			for i=1,#self.Entities do
				if self.Entities[i] and IsValid(self.Entities[i]) and self.Entities[i]:IsPlayer() and self.Entities[i]:Alive() then
					local avoidvec = (self.Entities[i]:GetPos() - self:GetPos())
					vec = vec - avoidvec:GetNormalized() * 10000000/(self.Entities[i]:Team()*self.Entities[i]:Team()*self.Entities[i]:Team()*self.Entities[i]:Team()*avoidvec:Length()+1)
					averagecount = averagecount+1
				end
			end
			vec = vec/averagecount
			local opt = {}
			opt.repath = 1
			self:MoveToPos( self:GetPos() + vec, opt )
		end
		--]]
		coroutine.yield()
	end
end

function ENT:OnStuck()
	--self.loco:Jump()
end

function ENT:Use( activator, caller, use_type, value)
	if(self.Saddle and activator and IsValid(self.Saddle) and IsValid(activator) and not self.Saddle:GetDriver() and activator:IsPlayer() and activator:Team() == TEAM_CORP_N) then
		activator:SetAllowWeaponsInVehicle(true)
		activator:EnterVehicle( self.Saddle )
		self.Saddle:SetCameraDistance(128)
		self:ToggleControls(activator, true)
	end
end

function ENT:PhysicsCollide( data, phys )
	if(self.Saddle and data.Entity and IsValid(self.Saddle) and IsValid(data.Entity) and not self.Saddle:GetDriver() and data.Entity:IsPlayer() and data.Entity:Team() == TEAM_CORP_N) then
		data.Entity:SetAllowWeaponsInVehicle(true)
		data.Entity:EnterVehicle( self.Saddle )
		self.Saddle:SetCameraDistance(128)
		self:ToggleControls(data.Entity,true)
	end
end

function ENT:OnInjured(dmginfo)
	if dmginfo:GetAttacker() != self.Saddle:GetDriver() and self:Health() <=0 then 
		if self.Saddle:GetDriver() and IsValid(self.Saddle:GetDriver()) then
			self:ToggleControls(self.Saddle:GetDriver(),false)
		end
		if self.Saddle and IsValid(self.Saddle) then
			self.Saddle:Remove()
		end
		--net.Start("horseragdoll")
		--net.WriteVector(self:GetPos())
		--net.Broadcast()
		--self:BecomeRagdollOnClient() 
		self:Remove()
	end
end

function ENT:OnKilled(dmginfo)
	if dmginfo:GetAttacker() != self.Saddle:GetDriver() and self:Health() <=0 then 
		if self.Saddle:GetDriver() and IsValid(self.Saddle:GetDriver()) then
			self:ToggleControls(self.Saddle:GetDriver(),false)
		end
		if self.Saddle and IsValid(self.Saddle) then
			self.Saddle:Remove()
		end
		--net.Start("horseragdoll")
		--net.WriteVector(self:GetPos())
		--net.Broadcast()
		--self:BecomeRagdollOnClient()
		self:Remove()
	end
end

function ENT:OnRemove()
	if self.Saddle:GetDriver() and IsValid(self.Saddle:GetDriver()) then
			self:ToggleControls(self.Saddle:GetDriver(),false)
	end
	if self.Saddle and IsValid(self.Saddle) then
		self.Saddle:Remove()
	end
end