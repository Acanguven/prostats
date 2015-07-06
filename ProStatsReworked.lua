local proStatsVersion = 1.0


class 'ProStats'
	function ProStats:__init()
		--self
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
		self.ranUpdater  = false
		self.commonReady = false
		self.spriteReady = false
		self.allReady = false
		AddTickCallback(function () self:Tick() end)
	end

	function Update:Tick()
		if not self.ranUpdater then
			GetAsyncWebResult("raw.githubusercontent.com" , self.versionLink, function(Data)
 	           local onlineVersion = tonumber(Data)
 	           if onlineVersion and onlineVersion > proStatsVersion then
 	           		print("<font color=\"#FF0000\">[Pro Stats]:</font> <font color=\"#FFFFFF\">Found Update: </font> <font color=\"#FF0000\">"..proStatsVersion.." > "..onlineVersion.." Updating... Don't F9!!</font>")
 	           		self.needUpdate = true
 	           end
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

		if not FileExist(LIB_PATH .. "/LawsUI.lua") then
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

		if not FileExist(SPRITE_PATH .. "/ProStats/stats-ui-empty.png") then
			if not self.dlSprite then
				self.dlSprite = true
				DownloadFile("https://raw.githubusercontent.com/thelaw44/prostats/master/stats-ui-empty.png", SPRITE_PATH .. "/ProStats/stats-ui-empty.png", function()
	                if FileExist(LIB_PATH .. "/LawsUI.lua") then
	                    print("<font color=\"#FF0000\">[Pro Stats]:</font> <font color=\"#FFFFFF\">Sprites downloaded</font>")
	                    self.dlSprite = false
	                end
	            end)
			end
		else
			self.spriteReady = true
		end

		if self.spriteReady and self.commonReady and not self.needUpdate then
			self.allReady = true
		end
	end

function OnLoad()
	print("Loaded")
	Update(proStatsVersion)
end
