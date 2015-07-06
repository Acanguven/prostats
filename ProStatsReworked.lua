local proStatsVersion = 1.0

class 'Update'
	function Update:__init(version)
		--|> Script info
		self.version     = version
		self.scriptLink  = "https://raw.githubusercontent.com/SkeemBoL/BoL/master/Katarina%20Rework.lua"
		self.versionLink = "https://raw.githubusercontent.com/SkeemBoL/BoL/master/Katarina%20Rework.version"
		self.path        = SCRIPT_PATH .. _ENV.FILE_NAME

		--|> Variables
		self.needUpdate  = false
		self.ranUpdater  = false

		--|> Callbacks
		AddTickCallback(function () self:Tick() end)
	end

	function Update:Tick()
		if not self.ranUpdater then
			GetAsyncWebResult("raw.github.com" , self.versionLink, function(Data)
 	           local onlineVersion = tonumber(Data)
 	           if onlineVersion and onlineVersion > proStatsVersion then
 	           		print("<font color=\"#FF0000\">[Nintendo Katarina]:</font> <font color=\"#FFFFFF\">Found Update: </font> <font color=\"#FF0000\">"..proStatsVersion.." > "..onlineVersion.." Updating... Don't F9!!</font>")
 	           		self.needUpdate = true
 	           end
 	        end)
			self.ranUpdater = true
		end
		if self.needUpdate then
			DownloadFile(self.scriptLink, self.path, function()
                if FileExist(self.path) then
                    print("<font color=\"#FF0000\">[Nintendo Katarina]:</font> <font color=\"#FFFFFF\">updated! Double F9 to use new version!</font>")
                end
            end)
            self.needUpdate = false
		end
	end
end

function OnLoad()
	Update(proStatsVersion)
end
