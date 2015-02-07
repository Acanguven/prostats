require "LawsUI"
if not VIP_USER then 
	print("You have to be vip user to use Pro Stats")
	return 	
end
ui = LawsUi()
--Counters
local deathCount = 0
local minionCount = 0
local assistCount = 0
local killCount = 0
local killAvg = 0
local deathAvg = 0
local assistAvg = 0
local minionAvg = 0
local gameId = math.random(100000000)
--Gui settings
local locations = {
	killAvarage = {x=50,y=8,size=18},
	deathAvarage = {x=98,y=8,size=18},
	assistAvarage = {x=148,y=8,size=18},
	minionAvarage = {x=198,y=8,size=18},
	overall = {x=254,y=12,size=18},
	overallScore = {x=258,y=30,size=18},
	killStatus = {x=38,y=34,size=18},
	deathStatus = {x=87,y=34,size=18},
	assistStatus = {x=136,y=34,size=18},
	minionStatus = {x=215,y=34,size=18},
}
local colorScheme = {
	green = 0xFF00FF00,
	red = 0xFFFF0000,
	yellow = 0xFFFFFF00,
	blue = 0xFF00D7FF
}
--Mechanic settings
local updateProgress = false
local signedIn = false
local started = false
local lastUpdate = 0
local lastUpdateProg = 0
local lastInitReq = 0
local lastStartReq = 0
local disableFirst = false
if not FileExist(LIB_PATH .. "/ProStats/user.key") then
	local file = io.open(LIB_PATH .. "/ProStats/user.key", "w")
	file:write(GetUser()..tostring(math.random(10000)))
	file:close()
end
local file = io.open(LIB_PATH .. "/ProStats/user.key","r") 	 
local userKey = file:read("*l")
local host = "prostatsbol.herokuapp.com"
local startTime = GetInGameTimer()
local disableRecord = false
if startTime > 180 then
	disableRecord = true
	print("Game allready started. Disabled recording your game.")
end

function OnLoad()
	HookPackets()
	Stats = ui:addPage()
	
	StatsBar = Stats:addSprite(LIB_PATH .. "/ProStats/images/stats-ui-empty.png","StatsBar")
	StatsBar:setPosition((GetGame().WINDOW_W/2) - (StatsBar.width/2),0)
	killAvarage = Stats:addText("00")
	killAvarage:setPosition(StatsBar.x + locations.killAvarage.x,StatsBar.y + locations.killAvarage.y)
	killAvarage:setSize(locations.killAvarage.size)
	deathAvarage = Stats:addText("00")
	deathAvarage:setPosition(StatsBar.x + locations.deathAvarage.x,StatsBar.y + locations.deathAvarage.y)
	deathAvarage:setSize(locations.deathAvarage.size)
	assistAvarage = Stats:addText("00")
	assistAvarage:setPosition(StatsBar.x + locations.assistAvarage.x,StatsBar.y + locations.assistAvarage.y)
	assistAvarage:setSize(locations.assistAvarage.size)
	minionAvarage = Stats:addText("00000")
	minionAvarage:setPosition(StatsBar.x + locations.minionAvarage.x,StatsBar.y + locations.minionAvarage.y)
	minionAvarage:setSize(locations.minionAvarage.size)
	overallText = Stats:addText("Overall")
	overallText:setPosition(StatsBar.x + locations.overall.x,StatsBar.y + locations.overall.y)
	overallText:setSize(locations.overall.size)
	overallScoreText = Stats:addText("00.00%")
	overallScoreText:setPosition(StatsBar.x + locations.overallScore.x,StatsBar.y + locations.overallScore.y)
	overallScoreText:setSize(locations.overallScore.size)
	killStatus = Stats:addText("00%")
	killStatus:setPosition(StatsBar.x + locations.killStatus.x,StatsBar.y + locations.killStatus.y)
	killStatus:setSize(locations.killStatus.size)
	deathStatus = Stats:addText("00%")
	deathStatus:setPosition(StatsBar.x + locations.deathStatus.x,StatsBar.y + locations.deathStatus.y)
	deathStatus:setSize(locations.deathStatus.size)
	assistStatus = Stats:addText("00%")
	assistStatus:setPosition(StatsBar.x + locations.assistStatus.x,StatsBar.y + locations.assistStatus.y)
	assistStatus:setSize(locations.assistStatus.size)
	minionStatus = Stats:addText("00%")
	minionStatus:setPosition(StatsBar.x + locations.minionStatus.x,StatsBar.y + locations.minionStatus.y)
	minionStatus:setSize(locations.minionStatus.size)
	Stats:show()


end

function OnDraw()
	if signedIn then
		Stats:show()
	else
		Stats:hide()
	end
	if not updateProgress then
		ui:drawManager()
	end
end

function OnRecvPacket(p)
	if p.header == 0x82 then
		p.pos = 18
		local aType = p:Decode1()
		p.pos = 2
        local target = p:Decode1()
		
		if target == 25 then
			if aType == 172 then
				deathCount = math.floor(deathCount) + 1
			else
				if aType == 27 then
					assistCount = math.floor(assistCount) + 1
				else
					killCount = math.floor(killCount) + 1
				end
			end

		end
	end

	if p.header == 0x0011 then
		p.pos = 7
		if p:Decode1() ~= 236 then
			minionCount = math.floor(minionCount) + 1
		end		
	end
end

function init()
	if lastInitReq + 5000 < GetTickCount() then
		lastInitReq = GetTickCount()
		GetAsyncWebResult(host, "/prostats/init/"..userKey, tostring(math.random(1000)), function(x) 
			local responseArray = x:split(",")
			if responseArray[1] == "1" then
				signedIn = true
				print(responseArray[2])			
			else
				if responseArray[1] == "2" then
					signedIn = true
					disableFirst = true
					print("ProStats will be in spectate mode because this is your first game! Your account created.")
				else
					print("Error:"..responseArray[2])
				end
			end
		end)
	end
end

function startRecord()
	if lastStartReq + 5000 < GetTickCount() then
		lastStartReq = GetTickCount()
		GetAsyncWebResult(host, "/prostats/start/"..userKey, tostring(math.random(1000)), function(x) 
			local responseArray = x:split(",")
			if responseArray[1] == "1" then
				started = true
				print(responseArray[2])
			else
				print("Error:"..responseArray[2])
			end
		end)
	end
end

function OnTick()
	if signedIn then
		if not disableRecord then
			if started then
				if StatsBar.sprite.width then
					updateTick()
					updateStatus()
				end
			else
				startRecord()
			end
		else
			updateWithoutRecord()
			updateStatus()
		end
	else
		init()
	end
end

function updateWithoutRecord()
	if lastUpdate + 3000 < GetTickCount() then
	    lastUpdate = GetTickCount()
	    local params = "/prostats/stat/"..userKey.."/"..math.floor(GetInGameTimer())
	    GetAsyncWebResult(host, params, tostring(math.random(1000)), function(z) 
			local responseArray = z:split(",")
			if responseArray[1] == "1" and tonumber(responseArray[2]) ~= nil and tonumber(responseArray[3]) ~= nil and tonumber(responseArray[4]) ~= nil and tonumber(responseArray[5]) ~= nil then
				killAvarage.value = string.format("%02d",responseArray[2])
				killAvg = tonumber(responseArray[2])
				deathAvarage.value = string.format("%02d",responseArray[3])
				deathAvg = tonumber(responseArray[3])
				assistAvarage.value = string.format("%02d",responseArray[4])
				assistAvg = tonumber(responseArray[4])
				minionAvarage.value = string.format("%05d",responseArray[5])
				minionAvg = tonumber(responseArray[5])
			end
		end)
	end
end

function updateTick()
	if lastUpdate + 3000 < GetTickCount() then
	    lastUpdate = GetTickCount()
	    local params = "/prostats/tick/"..userKey.."/"..math.floor(killCount).."/"..math.floor(deathCount).."/"..math.floor(assistCount).."/"..math.floor(minionCount).."/"..math.floor(GetInGameTimer()).."/"..gameId
		GetAsyncWebResult(host, params, tostring(math.random(1000)), function(z) 
			local responseArray = z:split(",")
			if responseArray[1] == "1" and tonumber(responseArray[2]) ~= nil and tonumber(responseArray[3]) ~= nil and tonumber(responseArray[4]) ~= nil and tonumber(responseArray[5]) ~= nil then
				killAvarage.value = string.format("%02d",responseArray[2])
				killAvg = tonumber(responseArray[2])
				deathAvarage.value = string.format("%02d",responseArray[3])
				deathAvg = tonumber(responseArray[3])
				assistAvarage.value = string.format("%02d",responseArray[4])
				assistAvg = tonumber(responseArray[4])
				minionAvarage.value = string.format("%05d",responseArray[5])
				minionAvg = tonumber(responseArray[5])
			else
				--print(z)
			end
		end)
	end
end

function updateStatus()
	if not updateProgress and lastUpdateProg + 200 < GetTickCount() and not disableFirst then
		lastUpdateProg = GetTickCount()
		updateProgress = true
		local killTempAvg = (tonumber(killCount)/tonumber(killAvg))*100
		if not (tonumber(killCount)== 0 and tonumber(killAvg) ==0) then
			killTempAvg = killTempAvg - 100
		else
			killTempAvg = 0
		end

		if killTempAvg > 99 then
			killTempAvg = 99
		end
		if killTempAvg < -99 then
			killTempAvg = -99
		end

		if killTempAvg > 10 then
			killStatus.color = colorScheme.blue
			killAvarage.color = colorScheme.blue
		else
			if killTempAvg > 0 then
				killStatus.color = colorScheme.green
				killAvarage.color = colorScheme.green
			else
				if killTempAvg > -10 then
					killStatus.color = colorScheme.yellow
					killAvarage.color = colorScheme.yellow
				else
					killStatus.color = colorScheme.red
					killAvarage.color = colorScheme.red
				end
			end
		end
		if killTempAvg < 0 then
			killTempAvg = killTempAvg * -1
		end
		killStatus.value = ""..math.floor(killTempAvg/10)..""..math.floor((killTempAvg%10)).."%"

		--
		local deathTempAvg = (deathCount/tonumber(deathAvg))*100
		if not (tonumber(deathCount)== 0 and tonumber(deathAvg) ==0) then
			deathTempAvg = deathTempAvg - 100
		else
			deathTempAvg = 0
		end
		if deathTempAvg > 99 then
			deathTempAvg = 99
		end
		if deathTempAvg < -99 then
			deathTempAvg = -99
		end
		if deathTempAvg > 10 then
			deathStatus.color = colorScheme.red
			deathAvarage.color = colorScheme.red
		else
			if deathTempAvg > 0 then
				deathStatus.color = colorScheme.yellow
				deathAvarage.color = colorScheme.yellow
			else
				if deathTempAvg > -10 then
					deathStatus.color = colorScheme.green
					deathAvarage.color = colorScheme.green
				else
					deathStatus.color = colorScheme.blue
					deathAvarage.color = colorScheme.blue
				end
			end
		end
		if deathTempAvg < 0 then
			deathTempAvg = deathTempAvg * -1
		end
		deathStatus.value = ""..math.floor(deathTempAvg/10)..""..math.floor((deathTempAvg%10)).."%"
		--

		local assistsTempAvg = (assistCount/assistAvg)*100
		if not (tonumber(assistCount)== 0 and tonumber(assistAvg) ==0) then
			assistsTempAvg = assistsTempAvg - 100
		else
			assistsTempAvg = 0
		end
		if assistsTempAvg > 99 then
			assistsTempAvg = 99
		end
		if assistsTempAvg < -99 then
			assistsTempAvg = -99
		end
		
		if assistsTempAvg > 10 then
			assistStatus.color = colorScheme.blue
			assistAvarage.color = colorScheme.blue
		else
			if assistsTempAvg > 0 then
				assistStatus.color = colorScheme.green
				assistAvarage.color = colorScheme.green
			else
				if assistsTempAvg > -10 then
					assistStatus.color = colorScheme.yellow
					assistAvarage.color = colorScheme.yellow
				else
					assistStatus.color = colorScheme.red
					assistAvarage.color = colorScheme.red
				end
			end
		end
		if assistsTempAvg < 0 then
			assistsTempAvg = assistsTempAvg * -1
		end
		assistStatus.value = ""..math.floor(assistsTempAvg/10)..""..math.floor((assistsTempAvg%10)).."%"
		--
		local minionTempAvg = (minionCount/tonumber(minionAvg))*100
		if not (tonumber(minionCount)== 0 and tonumber(minionAvg) ==0) then
			minionTempAvg = minionTempAvg - 100
		else
			minionTempAvg = 0
		end
		if minionTempAvg > 99 then
			minionTempAvg = 99
		end
		if minionTempAvg < -99 then
			minionTempAvg = -99
		end
		if minionTempAvg > 10 then
			minionStatus.color = colorScheme.blue
			minionAvarage.color = colorScheme.blue
		else
			if minionTempAvg > 0 then
				minionStatus.color = colorScheme.green
				minionAvarage.color = colorScheme.green
			else
				if minionTempAvg > -10 then
					minionStatus.color = colorScheme.yellow
					minionAvarage.color = colorScheme.yellow
				else
					minionStatus.color = colorScheme.red
					minionAvarage.color = colorScheme.red
				end
			end
		end
		if minionTempAvg < 0 then
			minionTempAvg = minionTempAvg * -1
		end
		minionStatus.value = ""..math.floor(minionTempAvg/10)..""..math.floor((minionTempAvg%10)).."%"
		--
		--Overall Calculation
		local avgTotal = tonumber(minionAvg)*20 + tonumber(killAvg)*200 + tonumber(assistAvg)*100 - tonumber(deathAvg)*200
		local currentTotal = tonumber(assistCount)*20 + tonumber(killCount)*200 + tonumber(assistCount)*100 - tonumber(deathCount)*200
		local overalTempAvarage = (currentTotal/avgTotal)*100
		if not (tonumber(currentTotal)== 0 and tonumber(avgTotal) ==0) then
			overalTempAvarage = overalTempAvarage - 100
		else
			overalTempAvarage = 0
		end
		if overalTempAvarage > 99 then
			overalTempAvarage = 99
		end
		if overalTempAvarage < -99 then
			overalTempAvarage = -99
		end
		if overalTempAvarage > 20 then
			overallScoreText.color = colorScheme.blue
			overallText.color = colorScheme.blue
		else
			if overalTempAvarage > 0 then
				overallScoreText.color = colorScheme.green
				overallText.color = colorScheme.green
			else
				if overalTempAvarage > -20 then
					overallScoreText.color = colorScheme.yellow
					overallText.color = colorScheme.yellow
				else
					overallScoreText.color = colorScheme.red
					overallText.color = colorScheme.red
				end
			end
		end	
		if overalTempAvarage < 0 then
			overalTempAvarage = overalTempAvarage * -1
		end
		overallScoreText.value = ""..string.format("%.2f",overalTempAvarage).."%"
		updateProgress = false
	end
end
