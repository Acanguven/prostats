local proStatsVersion = 1.0


class 'ProStats'
	function ProStats:__init()
		require "LawsUI"
		self.ui = LawsUi()
		self.firstRun = false
		if not FileExist(LIB_PATH .. "/ProStats.db") then
			self.firstRun = true
			self:storeData("")
		end
		
		self.datas = {}
		self.gameName = false
		self.panelHidden = false
		self.lastLog = 1
		self.locations = {
			killAvarage = {x=50,y=8,size=18},
			deathAvarage = {x=98,y=8,size=18},
			assistAvarage = {x=148,y=8,size=18},
			minionAvarage = {x=198,y=8,size=18},
			overallText = {x=254,y=12,size=18},
			overallScore = {x=255,y=30,size=18},
			killStatus = {x=30,y=34,size=18},
			deathStatus = {x=80,y=34,size=18},
			assistStatus = {x=130,y=34,size=18},
			minionStatus = {x=180,y=34,size=18},
		}
		self.colorScheme = {
			green = 0xFF00FF00,
			red = 0xFFFF0000,
			yellow = 0xFFFFFF00,
			blue = 0xFF00D7FF,
			orange = 0xFFDF6928,
		}
		self.scores = {
			killCurrent = 0,
			deathCurrent = 0,
			assistCurrent = 0,
			minionCurrent = 0,
			kill = 0,
			death = 0,
			overall = 0,
			assist = 0,
			minion = 0,
			killStatus = {data=0,positive=false},
			deathStatus = {data=0,positive=false},
			assistStatus = {data=0,positive=false},
			minionStatus = {data=0,positive=false}, 
		}


		self.menu = scriptConfig('Pro Stats', 'prostats')
		self.menu:addParam('heroBased',  'Champion specific stats',  SCRIPT_PARAM_ONOFF, false)
		self.menu.heroBased = false
		self.menu:addParam('recordOff',  'Disable game recording',  SCRIPT_PARAM_ONOFF, false)
		self.menu.recordOff = false
		self.menu:addParam("version", "Script Version", SCRIPT_PARAM_INFO, proStatsVersion)


		self:createLogTable()

		if self.firstRun then
			print("<font color=\"#FF0000\">[Pro Stats]:</font> <font color=\"#FFFFFF\">Welcome to Pro Stats, this is your first time using this awesome tool! So scripts status will be in idle mode. Please do not make f9 in game! Pro Stats will be working with full functionality when you use it second time.</font>")
		end

		if self:getSecondStats(5).new then
			print("<font color=\"#FF0000\">[Pro Stats]:</font> <font color=\"#FFFFFF\">This your first time playing ".. myHero.charName ..", so hero based stats will be disabled for this game.</font>")
			self.menu.heroBased = false
		end


		self:createViews()
		AddTickCallback(function() self:updateViews() end)
		AddTickCallback(function() self:updateState() end)
		AddRecvPacketCallback2(function(p) self:tracePackets(p) end)
		AddTickCallback(function() self:updateCurrentStats() end)
		
		

		if GetInGameTimer() > 90 then
			self.menu.recordOff = true
			print("<font color=\"#FF0000\">[Pro Stats]:</font> <font color=\"#FFFFFF\">Game recording disabled, you ran Pro Stats after 1:30. You can enable it manually from shift menu.</font>")
		end
	end

	function ProStats:createViews()
		self.statsPage = self.ui:addPage()
		self.statsBar = self.statsPage:addSprite(SPRITE_PATH .. "/stats-ui-empty.png","StatsBar")
		self.statsBar:setPosition((GetGame().WINDOW_W/2) - (self.statsBar.width/2),0)
		self.statsPage:show()
		self.statsBar:setLayer(2)

		self.extendButton = self.statsPage:addSprite(SPRITE_PATH .. "/extendButton.png","StatsBar")
		self.extendButton:setScale(50,50)
		self.extendButton:setLayer(1)
		self.extendButton:setPosition((GetGame().WINDOW_W/2) - (self.extendButton.width/2),55)
		self.extendButton:On("mouseup", function() 
			self.panelHidden = not self.panelHidden
			self.panelNeedUpdate = true
		end)

		self.killAvarage = self.statsPage:addText(self:ntos(self.scores.kill,2))
		self.killAvarage:setPosition(self.statsBar.x + self.locations.killAvarage.x, self.statsBar.y + self.locations.killAvarage.y)
		self.killAvarage:setSize(self.locations.killAvarage.size)
		self.killAvarage:setLayer(3)

		self.deathAvarage = self.statsPage:addText(self:ntos(self.scores.death,2))
		self.deathAvarage:setPosition(self.statsBar.x + self.locations.deathAvarage.x, self.statsBar.y + self.locations.deathAvarage.y)
		self.deathAvarage:setSize(self.locations.deathAvarage.size)
		self.deathAvarage:setLayer(3)

		self.assistAvarage = self.statsPage:addText(self:ntos(self.scores.assist,2))
		self.assistAvarage:setPosition(self.statsBar.x + self.locations.assistAvarage.x, self.statsBar.y + self.locations.assistAvarage.y)
		self.assistAvarage:setSize(self.locations.assistAvarage.size)
		self.assistAvarage:setLayer(3)

		self.minionAvarage = self.statsPage:addText(self:ntos(self.scores.minion,5))
		self.minionAvarage:setPosition(self.statsBar.x + self.locations.minionAvarage.x, self.statsBar.y + self.locations.minionAvarage.y)
		self.minionAvarage:setSize(self.locations.minionAvarage.size)
		self.minionAvarage:setLayer(3)

		self.overallText = self.statsPage:addText("Overall")
		self.overallText:setPosition(self.statsBar.x + self.locations.overallText.x, self.statsBar.y + self.locations.overallText.y)
		self.overallText:setSize(self.locations.overallText.size)
		self.overallText:setLayer(3)

		self.overallScore = self.statsPage:addText(self:ntos(0,6))
		self.overallScore:setPosition(self.statsBar.x + self.locations.overallScore.x, self.statsBar.y + self.locations.overallScore.y)
		self.overallScore:setSize(self.locations.overallScore.size)
		self.overallScore:setLayer(3)

		self.killStatus = self.statsPage:addText(self:ntos(self.scores.killStatus.data,3))
		self.killStatus:setPosition(self.statsBar.x + self.locations.killStatus.x, self.statsBar.y + self.locations.killStatus.y)
		self.killStatus:setSize(self.locations.killStatus.size)
		self.killStatus:setLayer(3)

		self.deathStatus = self.statsPage:addText(self:ntos(self.scores.deathStatus.data,3))
		self.deathStatus:setPosition(self.statsBar.x + self.locations.deathStatus.x, self.statsBar.y + self.locations.deathStatus.y)
		self.deathStatus:setSize(self.locations.deathStatus.size)
		self.deathStatus:setLayer(3)

		self.assistStatus = self.statsPage:addText(self:ntos(self.scores.assistStatus.data,3))
		self.assistStatus:setPosition(self.statsBar.x + self.locations.assistStatus.x, self.statsBar.y + self.locations.assistStatus.y)
		self.assistStatus:setSize(self.locations.assistStatus.size)
		self.assistStatus:setLayer(3)

		self.minionStatus = self.statsPage:addText(self:ntos(self.scores.minionStatus.data,4))
		self.minionStatus:setPosition(self.statsBar.x + self.locations.minionStatus.x, self.statsBar.y + self.locations.minionStatus.y)
		self.minionStatus:setSize(self.locations.minionStatus.size)
		self.minionStatus:setLayer(3)
	end

	function ProStats:updateViews()
		if self.panelNeedUpdate then
			self.lastWindowWidth = WINDOW_W
			self.panelNeedUpdate = false
			if not self.panelHidden then
				self.statsBar:setPosition((GetGame().WINDOW_W/2) - (self.statsBar.width/2),0)
				self.extendButton:setPosition((GetGame().WINDOW_W/2) - (self.extendButton.width/2),55)
			else
				self.statsBar:setPosition((GetGame().WINDOW_W/2) - (self.statsBar.width/2),-60)
				self.extendButton:setPosition((GetGame().WINDOW_W/2) - (self.extendButton.width/2),-5)
			end
			self.killAvarage:setPosition(self.statsBar.x + self.locations.killAvarage.x, self.statsBar.y + self.locations.killAvarage.y)
			self.assistAvarage:setPosition(self.statsBar.x + self.locations.assistAvarage.x, self.statsBar.y + self.locations.assistAvarage.y)
			self.deathAvarage:setPosition(self.statsBar.x + self.locations.deathAvarage.x, self.statsBar.y + self.locations.deathAvarage.y)
			self.minionAvarage:setPosition(self.statsBar.x + self.locations.minionAvarage.x, self.statsBar.y + self.locations.minionAvarage.y)
			self.overallText:setPosition(self.statsBar.x + self.locations.overallText.x, self.statsBar.y + self.locations.overallText.y)
			self.killStatus:setPosition(self.statsBar.x + self.locations.killStatus.x, self.statsBar.y + self.locations.killStatus.y)
			self.overallScore:setPosition(self.statsBar.x + self.locations.overallScore.x, self.statsBar.y + self.locations.overallScore.y)
			self.deathStatus:setPosition(self.statsBar.x + self.locations.deathStatus.x, self.statsBar.y + self.locations.deathStatus.y)
			self.assistStatus:setPosition(self.statsBar.x + self.locations.assistStatus.x, self.statsBar.y + self.locations.assistStatus.y)
			self.minionStatus:setPosition(self.statsBar.x + self.locations.minionStatus.x, self.statsBar.y + self.locations.minionStatus.y)
		end
	end

	function ProStats:updateCurrentStats()
		if not self.firstRun then
			self.killAvarage.text = self:ntos(self.scores.kill,2)
			self.deathAvarage.text = self:ntos(self.scores.death,2)
			self.assistAvarage.text = self:ntos(self.scores.assist,2)
			self.minionAvarage.text = self:ntos(self.scores.minion,5)
			self.overallScore.text = self:ntos(self.scores.overall,6)

			self.killStatus.text = self:ntos(self.scores.killStatus.data,3)
			self.killStatus.color = self:getcolor(self.scores.killStatus)
			self.killAvarage.color = self.killStatus.color

			self.deathStatus.text = self:ntos(self.scores.deathStatus.data,3)
			self.deathStatus.color = self:getcolor(self.scores.deathStatus)
			self.deathAvarage.color = self.deathStatus.color

			self.assistStatus.text = self:ntos(self.scores.assistStatus.data,3)
			self.assistStatus.color = self:getcolor(self.scores.assistStatus)
			self.assistAvarage.color = self.assistStatus.color

			self.minionStatus.text = self:ntos(self.scores.minionStatus.data,4)
			self.minionStatus.color = self:getcolor(self.scores.minionStatus)
			self.minionAvarage.color = self.minionStatus.color

			self.overallScore.text = self:ntos(self.scores.overallScore.data,6)
			self.overallScore.color = self:getcolor(self.scores.overallScore)
			self.overallText.color = self.overallScore.color
		end
	end

	function ProStats:getcolor(stat)
		if stat.positive then
			if stat.data <= 20 then
				return self.colorScheme.yellow
			end
			if stat.data <= 50 then
				return self.colorScheme.blue
			end
			if stat.data <= 200 then
				return self.colorScheme.green
			end
		else
			if stat.data <= 20 then
				return self.colorScheme.yellow
			end
			if stat.data <= 50 then
				return self.colorScheme.orange
			end
			if stat.data <= 200 then
				return self.colorScheme.red
			end
		end
	end

	function ProStats:ntos(text,d)
		local ret = text
		if d == 2 then
			ret = string.format("%02d",text)
		elseif d == 5 then
			ret = string.format("%05d",text)
		elseif d == 6 then
			ret = string.format("%.2f",text).."%"
		elseif d == 3 then
			ret = string.format("%03d",text) .. "%"
		elseif d == 4 then
			ret = string.format("%.3f",text) .. "%"
		end
		return ret
	end


	function ProStats:tracePackets(p)
        p.pos = 2
        local heroID = p:DecodeF()
        local hero = objManager:GetObjectByNetworkId(heroID)
        if myHero == hero then
			if p.header == 0x0B then
	        	p.pos = 9
	        	local type = p:Decode1()
		        if type == 236 then
		            self.scores.minionCurrent = self.scores.minionCurrent + 1
		        end
		    end

		    if p.header == 0x0109 then
		        p.pos = 18
		        local type = p:Decode1()
		        if type == 0xFD then
		            self.scores.deathCurrent = self.scores.deathCurrent + 1
		        else
		        	if type == 0xCD  then
			            self.scores.assistCurrent = self.scores.assistCurrent + 1
			        else
			            self.scores.killCurrent = self.scores.killCurrent + 1
			        end
			    end
		    end
	    end
	end

	function ProStats:updateState()
		if self.lastLog + 1 < GetInGameTimer() then
			self.lastLog = GetInGameTimer()
			if not self.menu.recordOff then
				saveString = "#"..string.format("%d",GetInGameTimer()).."|"..self.scores.killCurrent .. "|" .. self.scores.deathCurrent .. "|" .. self.scores.assistCurrent .. "|" .. self.scores.minionCurrent .. "|" ..myHero.charName
				self:storeData(saveString)
			end
			local update = self:getSecondStats()
			self.scores.kill = update.kill
			self.scores.death = update.death
			self.scores.assist = update.assist
			self.scores.minion = update.minion

			self.scores.deathStatus = self:calculateAvg(self.scores.death,self.scores.deathCurrent,true)
			self.scores.killStatus = self:calculateAvg(self.scores.kill,self.scores.killCurrent,false)
			self.scores.assistStatus = self:calculateAvg(self.scores.assist,self.scores.assistCurrent,false)
			self.scores.minionStatus = self:calculateAvg(self.scores.minion,self.scores.minionCurrent,false)
			self.scores.overallScore = self:calculateAvg(self.scores.kill*10+self.scores.minion+self.scores.assist*5-self.scores.death*10,self.scores.killCurrent*10+self.scores.minionCurrent+self.scores.assistCurrent*5-self.scores.deathCurrent*10,false)
		end
	end

	function ProStats:calculateAvg(old,current,reverse)
		old = tonumber(old)
		current = tonumber(current)
		if reverse then
			if not (old == 0 and current == 0) then
				return {data = (math.abs(old-current)/((old+current)/2))*100,positive=(old > current)}
			else
				return {data = 0,positive=true}
			end
		else
			if not (old == 0 and current == 0) then
				return {data = (math.abs(old-current)/((old+current)/2))*100,positive=(old < current)}
			else
				return {data = 0,positive=false}
			end
		end
	end

	function ProStats:storeData(str)
		local writeDb = io.open(LIB_PATH .. "/ProStats.db", "a")
		writeDb:write(str)
		writeDb:close()
	end

	function ProStats:createLogTable()
		self.readDb = io.open(LIB_PATH .. "/ProStats.db","r")
		local content = self.readDb:read("*all")
		local endData = {}
		local datas = content:split("#")
		for key,data in pairs(datas) do 
			local nData = data:split("|")
			if tonumber(nData[1]) ~= nil then
				table.insert(endData,{second=nData[1],kill=nData[2],death=nData[3],assist=nData[4],minion=nData[5],champion=nData[6]})
			end
		end
		self.readDb:close()
		self.datas = endData
	end

	function ProStats:getSecondStats(second,champion)
		local sc = second
		local ch = champion

		if sc == nil then
			sc = string.format("%d",GetInGameTimer())
		else
			sc = string.format("%d",sc)
		end

		if ch == nil then
			ch = myHero.charName
		end

		local stat = {
			kill = 0,
			death = 0,
			assist = 0,
			minion = 0,
			new = true
		}

		local iteration = 0

		for _,v in pairs(self.datas) do
			if ch == v.champion or not self.menu.heroBased then
				stat.new = false
			    if math.abs(tonumber(v.second) - sc) <= 5 then
			    	stat.kill = stat.kill + v.kill
			    	stat.death = stat.death + v.death
			    	stat.assist = stat.assist + v.assist
			    	stat.minion = stat.minion + v.minion
			    	iteration = iteration + 1
			    end
			end
		end


		if iteration > 0 then
			stat.kill = string.format("%d",stat.kill/iteration)
			stat.death = string.format("%d",stat.death/iteration)
			stat.assist = string.format("%d",stat.assist/iteration)
			stat.minion = string.format("%d",stat.minion/iteration)
			return stat
		else
			return{kill = 0,death = 0,assist = 0,minion = 0,new=stat.new}
		end
		
	end








class 'Update'
	function Update:__init(version)
		self.version     = version
		self.scriptLink  = "https://raw.githubusercontent.com/thelaw44/prostats/master/ProStatsReworked.lua"
		self.versionLink = "/thelaw44/prostats/master/ProStatsReworked.version".."?random="..math.random(1,10000)
		self.path        = SCRIPT_PATH .. _ENV.FILE_NAME
		self.dlLib = false
		self.dlSprite = false
		self.needUpdate  = false
		self.versionChecked = false
		self.ranUpdater  = false
		self.commonReady = false
		self.spriteReady = false
		self.allReady = false
		AddTickCallback(function () self:Tick() end)
	end

	function Update:Tick()
		if not self.allRready and not self.ranUpdater then
			GetAsyncWebResult("raw.githubusercontent.com" , self.versionLink, function(Data)
 	           local onlineVersion = tonumber(Data)
 	           if onlineVersion and onlineVersion > proStatsVersion then
 	           		print("<font color=\"#FF0000\">[Pro Stats]:</font> <font color=\"#FFFFFF\">Found Update: </font> <font color=\"#FF0000\">"..proStatsVersion.." > "..onlineVersion.." Updating... Don't F9!!</font>")
 	           		self.needUpdate = true
 	           end
 	           self.versionChecked = true
 	        end)
			self.ranUpdater = true
		end
		if self.needUpdate then
			DownloadFile(self.scriptLink, self.path, function()
                if FileExist(self.path) then
                    print("<font color=\"#FF0000\">[Pro Stats]:</font> <font color=\"#FFFFFF\">updated! Double F9 to use new version!</font>")
                end
            end)
            self.needUpdate = false
		end

		if not self.allRready and not FileExist(LIB_PATH .. "/LawsUI.lua") then
			if not self.dlLib then
				self.dlLib = true
				DownloadFile("https://raw.githubusercontent.com/thelaw44/LawsUI/master/common/LawsUI.lua", LIB_PATH .. "/LawsUI.lua", function()
	                if FileExist(LIB_PATH .. "/LawsUI.lua") then
	                    print("<font color=\"#FF0000\">[Pro Stats]:</font> <font color=\"#FFFFFF\">Laws UI downloaded.</font>")
	                    self.dlLib = false
	                end
	            end)
			end
		else
			self.commonReady = true
		end

		if not self.allRready and (not FileExist(SPRITE_PATH .. "/stats-ui-empty.png") or not FileExist(SPRITE_PATH .. "/extendButton.png")) then
			if not self.dlSprite then
				self.dlSprite = true
				if not FileExist(SPRITE_PATH .. "/stats-ui-empty.png") then
					DownloadFile("https://raw.githubusercontent.com/thelaw44/prostats/master/stats-ui-empty.png", SPRITE_PATH .. "/stats-ui-empty.png", function()
		                if FileExist(SPRITE_PATH .. "/stats-ui-empty.png") then
		                    print("<font color=\"#FF0000\">[Pro Stats]:</font> <font color=\"#FFFFFF\">Sprite downloaded.</font>")
		                    self.dlSprite = false
		                end
		            end)
				end
				if not FileExist(SPRITE_PATH .. "/extendButton.png") then
		            DownloadFile("https://raw.githubusercontent.com/thelaw44/prostats/master/extendButton.png", SPRITE_PATH .. "/extendButton.png", function()
		                if FileExist(SPRITE_PATH .. "/stats-ui-empty.png") then
		                    print("<font color=\"#FF0000\">[Pro Stats]:</font> <font color=\"#FFFFFF\">Sprite downloaded.</font>")
		                    self.dlSprite = false
		                end
		            end)
		        end
			end
		else
			self.spriteReady = true
		end

		if not self.allRready and self.spriteReady and self.commonReady and not self.needUpdate and self.versionChecked then
			print("<font color=\"#FF0000\">[Pro Stats]:</font> <font color=\"#FFFFFF\">Script validated, gl hf.</font>")
			self.allRready = true
			ProStats()
		end
	end

function OnLoad()
	if not VIP_USER then 
		print("<font color=\"#FF0000\">[Pro Stats]:</font> <font color=\"#FFFFFF\">You have to be vip to use Pro Stats.</font>")
		return 	
	else
		HookPackets()
		Update(proStatsVersion)
	end
end
