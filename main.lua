local websocketLibrary = (syn and syn.websocket) or (Krnl and Krnl.WebSocket) or WebSocket
if(not websocketLibrary) then return error("Exploit doesn't support websockets") end

local module = {}

local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")

module.connect = function(ip,isMaster)
	local WebSocket = websocketLibrary.connect("ws://"..ip)

	module.rawOnMessage = WebSocket.OnMessage
	WebSocket.OnClose:Connect(function() error("Websocket isnt supposed to close") end)

	local connectData = HttpService:JSONDecode(WebSocket.OnMessage:Wait())

	WebSocket:Send(HttpService:JSONEncode(
		{
			["id"] = connectData.id;
			["password"] = connectData.password;
			["command"] = "load";
			["isMaster"] = isMaster
		}))

	module.password = connectData.password
	module.id = connectData.id
	module.isMaster = connectData.isMaster

	local TeleportFunction = Instance.new("BindableFunction")
	local ExecuteFunction = Instance.new("BindableFunction")
	local ClientJoined = Instance.new("BindableEvent")

	module.canTeleport = TeleportFunction
	module.canExecute = ExecuteFunction
	module.clientJoined = ClientJoined.Event

	TeleportFunction.OnInvoke = function() return true end
	ExecuteFunction.OnInvoke = function() return true end

	WebSocket.OnMessage:Connect(function(msg)
		local Data = HttpService:JSONDecode(msg)
		local Type,event = Data["type"],Data.event

		if event == "teleport" then
			if TeleportFunction:Invoke(Type,Data.id,Data.placeId,Data.place,Data.clients) then
				TeleportService:TeleportToPlaceInstance(Data.placeId,Data.place)
			end
		elseif event == "clientJoined" then
			ClientJoined:Fire(Data.id,Data.isMaster)
		elseif event == "execute" then
			if ExecuteFunction:Invoke(Type,Data.id,Data.code,Data.clients) then
				loadstring("local succes,err = pcall(function()"..Data.code.."end) if not succes then warn(err) end")()
			end
		end
	end)

	module.globalExecute = function(Code,Params)
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
	
	module.specificExecute = function(Clients,Code,Params)
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
	
	module.globalTeleport = function(placeId,jobId)
		WebSocket:Send(HttpService:JSONEncode({
			["id"] = connectData.id;
			["password"] = connectData.password;
			["command"] = "globalExecute";
			["placeId"] = placeId;
			["place"] = jobId;
		}))
	end

	module.specificTeleport = function(Clients,placeId,jobId)
		WebSocket:Send(HttpService:JSONEncode({
			["id"] = connectData.id;
			["password"] = connectData.password;
			["command"] = "globalExecute";
			["Clients"] = Clients;
			["placeId"] = placeId;
			["place"] = jobId;
		}))
	end
end

return module
