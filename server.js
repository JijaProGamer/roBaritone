const WebSocket = require("ws")
const http = require("http")
const express = require("express");
const uuid = require("uuid");

const app = express();

const server = http.createServer(app);
const wss = new WebSocket.Server({ server });

let Clients = {}
let DumpedData = {
    global: []
}

function isJSON(str) {
    try {
        return JSON.parse(str)
    } catch (e) {
        return false;
    }
}

function isData(object) {
    return object.id && object.password && object.command
}

wss.on('connection', (ws) => {
    let wsUuid = uuid.v4()
    let wsPass = uuid.v4()
    ws.isAlive = true;

    ws.on('message', (message) => {
        let data = isJSON(message) && JSON.parse(message)
        if (!data) {
            ws.send(JSON.stringify({ "error": "String is not JSON compatible" }))
            return ws.close()
        } else {
            if (!isData(data)) {
                ws.send(JSON.stringify({ "error": "Body is not providing correct arguments" }))
                return ws.close()
            }
            let id = data.id
            let password = data.password
            let command = data.command
            if (!(id == wsUuid && Clients[id].password == password)) {
                ws.send(JSON.stringify({ "error": "Body is not providing correct arguments" }))
                return ws.close()
            }

            if(command=="ping"){
                Clients[id].ping = 1
            }

            if (!Clients[id].isLoaded) {
                if (!command == "load") {
                    console.log(1)
                    ws.send(JSON.stringify({ "error": "Cannot use commands without loading first" }))
                    return ws.close()
                }
            }
            switch (command) {
                case "load":
                    Clients[id].isMaster = data.isMaster == true || false
                    Clients[id].isLoaded = true
                    Clients[id].ping = 0
                    wss.clients.forEach(client => {
                        if (client != ws) {
                            client.send(JSON.stringify({ type: "broadcast", event: "clientJoined", id: id, isMaster: data.isMaster }));
                        }
                    });
                    break;
                case "listMembers":
                    var members = {};
                    for (var key of Object.keys(Clients)) {
                        let clientData = Clients[key]
                        if (clientData.isLoaded && !(key == id)) {
                            members[id] = { isMaster: clientData.isMaster, id: clientData.id }
                        }
                    }
                    ws.send(JSON.stringify(members))
                    break;
                case "globalExecute":
                    if (!Clients[id].isMaster) {
                        ws.send(JSON.stringify({ "error": "Command locked for master" }))
                        return ws.close()
                    }
                    wss.clients.forEach(client => {
                        client.send(JSON.stringify({ type: "broadcast", event: "execute", id: id, code: data.script }));
                    })
                    break;
                case "globalTeleport":
                    if (!Clients[id].isMaster) {
                        ws.send(JSON.stringify({ "error": "Command locked for master" }))
                        return ws.close()
                    }

                    wss.clients.forEach(client => {
                        client.send(JSON.stringify({ type: "broadcast", event: "teleport", id: id, placeId: data.placeId, place: data.place }));
                    })
                    break;
                case "execute":
                    if (!Clients[id].isMaster) {
                        ws.send(JSON.stringify({ "error": "Command locked for master" }))
                        return ws.close()
                    }
                    var clients = data.Clients

                    Clients.forEach(client => {
                        if (clients.includes(client)) {
                            client.connection.send(JSON.stringify({ type: "specific", event: "execute", id: id, code: data.script, clients: clients }));
                        }
                    })
                    break;
                case "teleport":
                    if (!Clients[id].isMaster) {
                        ws.send(JSON.stringify({ "error": "Command locked for master" }))
                        return ws.close()
                    }
                    var clients = data.Clients

                    Clients.forEach(client => {
                        if (clients.includes(client)) {
                            client.send(JSON.stringify({ type: "specific", event: "teleport", id: id, placeId: data.placeId, place: data.place, clients: clients }));
                        }
                    })
                    break;
                case "dumpData":
                        if (!Clients[id].isMaster) {
                            ws.send(JSON.stringify({ "error": "Command locked for master" }))
                            return ws.close()
                        }
                        
                        if(!DumpedData[data.scope || "global"]) DumpedData[data.scope || "global"] = []
                        DumpedData[data.scope || "global"].push(data.dataToDump)

                    break;
                case "getDumpedData":        
                    return ws.send(JSON.stringify(DumpedData[data.scope || "global"]))
                case "disconnect":        
                    delete Clients[wsUuid]
                    return ws.close()
                case "clearDumpedData":
                        if (!Clients[id].isMaster) {
                            ws.send(JSON.stringify({ "error": "Command locked for master" }))
                            return ws.close()
                        }

                        if (!data.scope || data.scope == "global") {
                            ws.send(JSON.stringify({ "error": "Body is not providing correct arguments" }))
                            return ws.close()
                        }

                        delete DumpedData[data.scope]
                    break;
            }
        }
    });

    Clients[wsUuid] = { id: wsUuid, password: wsPass, isLoaded: false,ping: -1}

    setTimeout(function() {
        ws.send(JSON.stringify(Clients[wsUuid]))
        Clients[wsUuid].connection = ws
    }, 100);
});

setInterval(function(){
    for(var client in Clients){
        clientObject = Clients[client]

        switch(clientObject.ping){
            case -1:
                break;
            case 1:
                clientObject.ping = 0
                break;
            case 0:
                clientObject.connection.send(JSON.stringify({error: "Client has a ping of over 5000ms or is inactive"}))
                clientObject.connection.close()

                delete Clients[client]
                break;
        }
    }
},5000)

server.listen(8999, () => {
    console.log(`Server started on port ${server.address().port}`);
});
