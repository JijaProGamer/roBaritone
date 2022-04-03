local succes,err = pcall(function()
    local roBaritone = loadstring(game:HttpGet("https://raw.githubusercontent.com/JijaProGamer/roBaritone/main/main.lua",true))()
    roBaritone = roBaritone.new("130.162.37.209:8999",true)
    
    roBaritone.globalExecute(readfile("some file from the workspace directory")--[[,{} A array of propieties. The executed script will use the value instead of EXTERNAL_PARAMETER_(index). For example EXTERNAL_PARAMETER_1]])
end)

if not succes then
    warn(err)
end
