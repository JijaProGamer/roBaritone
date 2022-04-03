local websocketLibrary = (syn and syn.websocket) or (Krnl and Krnl.WebSocket) or WebSocket
if not websocketLibrary then return error("Exploit doesn't support websockets") end

local module = {}
module.__index = module

local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

function module:ping()
	print(HttpService:JSONEncode(
		{
			["id"] = self.id;
			["password"] = self.password;
			["command"] = "ping";
		}))
	
	self.WebSocket:Send(HttpService:JSONEncode(
		{
			["id"] = self.id;
			["password"] = self.password;
			["command"] = "ping";
		}))
end

function module:connect()
	local WebSocket = websocketLibrary.connect("ws://"..self.ip)

	self.WebSocket = WebSocket

	local connectData = HttpService:JSONDecode(WebSocket.OnMessage:Wait())

	WebSocket:Send(HttpService:JSONEncode(
		{
			["id"] = connectData.id;
			["password"] = connectData.password;
			["command"] = "load";
			["isMaster"] = self.isMaster
		}))

	self.password = connectData.password
	self.id = connectData.id
	
	self:ping()

	coroutine.wrap(function()
		while task.wait(0.5) do
			self:ping()
		end
	end)()
	
	local TeleportFunction = Instance.new("BindableFunction")
	local ExecuteFunction = Instance.new("BindableFunction")
	local ClientJoined = Instance.new("BindableEvent")

	self.canTeleport = TeleportFunction
	self.canExecute = ExecuteFunction
	self.clientJoined = ClientJoined.Event

	TeleportFunction.OnInvoke = function() return true end
	ExecuteFunction.OnInvoke = function() return true end

	WebSocket.OnMessage:Connect(function(msg)
		print(msg)
		local Data = HttpService:JSONDecode(msg)
		local Type,event = Data["type"],Data.event

		if event == "teleport" then
			if TeleportFunction:Invoke(Type,Data.id,Data.placeId,Data.place,Data.clients) then
				if Data.place then
					TeleportService:TeleportToPlaceInstance(Data.placeId,Data.place)
				else
					TeleportService:Teleport(Data.placeId)
				end
			end
		elseif event == "clientJoined" then
			ClientJoined:Fire(Data.id,Data.isMaster)
		elseif event == "execute" then
			if ExecuteFunction:Invoke(Type,Data.id,Data.code,Data.clients) then
				loadstring("local succes,err = pcall(function()"..Data.code.."end) if not succes then warn(err) end")()
			end
		end
	end)

	self.globalExecute = function(Code,Params)
		for index,value in ipairs(Params) do
			value = tostring(value)
			Code = Code:gsub("EXTERNAL_PARAMETER_"..index, value)
		end
		WebSocket:Send(HttpService:JSONEncode({
			["id"] = connectData.id;
			["password"] = connectData.password;
			["command"] = "globalExecute";
			["script"] = Code
		}))
	end

	self.specificExecute = function(Clients,Code,Params)
		for index,value in ipairs(Params) do
			value = tostring(value)
			Code = Code:gsub("EXTERNAL_PARAMETER_"..index, value)
		end
		WebSocket:Send(HttpService:JSONEncode({
			["id"] = connectData.id;
			["password"] = connectData.password;
			["command"] = "execute";
			["script"] = Code;
			["Clients"] = Clients;
		}))
	end

	self.globalTeleport = function(placeId,jobId)
		WebSocket:Send(HttpService:JSONEncode({
			["id"] = connectData.id;
			["password"] = connectData.password;
			["command"] = "globalExecute";
			["placeId"] = placeId;
			["place"] = jobId;
		}))
	end

	self.specificTeleport = function(Clients,placeId,jobId)
		WebSocket:Send(HttpService:JSONEncode({
			["id"] = connectData.id;
			["password"] = connectData.password;
			["command"] = "globalExecute";
			["Clients"] = Clients;
			["placeId"] = placeId;
			["place"] = jobId;
		}))

		self.dumpData = function(scope,dataToDump)
			WebSocket:Send(HttpService:JSONEncode({
				["id"] = connectData.id;
				["password"] = connectData.password;
				["command"] = "dumpData";
				["scope"] = scope;
				["dataToDump"] = dataToDump;
			}))
		end

		self.dumpData = function(scope,dataToDump)
			WebSocket:Send(HttpService:JSONEncode({
				["id"] = connectData.id;
				["password"] = connectData.password;
				["command"] = "dumpData";
				["scope"] = scope;
				["dataToDump"] = dataToDump;
			}))
		end

		self.getDumpedData = function(scope)
			WebSocket:Send(HttpService:JSONEncode({
				["id"] = connectData.id;
				["password"] = connectData.password;
				["command"] = "getDumpedData";
				["scope"] = scope;
			}))
		end

		self.clearDumpedData = function(scope)
			WebSocket:Send(HttpService:JSONEncode({
				["id"] = connectData.id;
				["password"] = connectData.password;
				["command"] = "clearDumpedData";
				["scope"] = scope;
			}))
		end
	end
end

module.new = function(ip,isMaster)
	local mainModule = {}
	setmetatable(mainModule,module)

	mainModule.ip = ip
	mainModule.isMaster = isMaster

	mainModule:connect()

	return mainModule
end

return module
