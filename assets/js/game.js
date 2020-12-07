import "../css/app.scss"
import {Socket, Presence} from "phoenix"
import "phoenix_html"
import { Elm } from "../src/Game.elm";

const regeneratorRuntime = require("regenerator-runtime");

let roomCode = window.location.pathname.substr(6);
let username = sessionStorage.getItem("username");
let socket = new Socket("/socket", {params: {username: username, roomCode: roomCode}});
let channel = socket.channel('room:' + roomCode, {});
let presence = new Presence(channel);

let users  = [];
let isHost = (sessionStorage.getItem("isHost") === "Y");

function renderOnlineUsers(presence) {
    let count = presence.list().length;
    if(isHost) {
        users = []
        for (let i = 0; i < count; i++) {
            users.push(presence.list()[i]["metas"][0]["username"]);
        }
        channel.push('shout', {name: username,  body: "?userChange", users: users});
    }
    if(count === 1 && !isHost){
        channel.push('shout', {name: username,  body: "?cleanLobby"});
    }
    document.getElementById("presence-counter").innerText = `there are currently ${count} players in this room`;
}


socket.connect();
socket.onError(function x(){
    socket.disconnect();
    window.location = "/";
})

presence.onSync(() => renderOnlineUsers(presence))
channel.join();

var main = Elm.Game.init({
    node: document.getElementById('elm-game'),
    flags : {url: window.location.protocol + "//" + window.location.host}
});


//////// Init data Elm /////////
main.ports.messageReceiver.send(JSON.stringify({"?username": username}));
main.ports.messageReceiver.send(JSON.stringify({"?roomCode": roomCode}));
if(isHost){
    main.ports.messageReceiver.send("?isHost");
}
//////// End init data Elm /////////


main.ports.sendMessage.subscribe(async function(payload) {
        let message = JSON.parse(payload)
        console.log(message);
        switch (message.message){
            case "?bet":
                channel.push('shout', {name: username,  body: "?bet", color: message.color, bet: message.bet});
                break;
            case "?winner":
                getWinners(message.winner).then(function (winners){
                    main.ports.messageReceiver.send(JSON.stringify(winners));
                    const timeout = async ms => new Promise(res => setTimeout(res, ms));
                    confetti.start();
                    // timeout(10000).then(function(){window.location.href = "/"})
                })
                break;
            case "?flip":
                
            default:
                console.log(message.message);
                break;
        }
});

channel.on('shout', payload => {
    switch (payload.body) {
        case "?userChange":
            if(!isHost){
                users = payload.users;
            }
            break;
        case "?leaving":
            if(payload.name === username){
                isHost = true;
                window.isHost = true;
            }
            toastr.warning(payload.left + " has left the room")
            break;
        default:
            main.ports.messageReceiver.send(JSON.stringify(payload));
            break;
    }
});

async function getWinners(color){
    let response = await fetch(window.location.protocol + "//" + window.location.host + "/api/" + roomCode + "/users/" + color);
    return await response.json();
}