// We need to import the CSS so that webpack will load it.
// The MiniCssExtractPlugin is used to separate it out into
// its own CSS file.
import "../css/app.scss"

// webpack automatically bundles all modules in your
// entry points. Those entry points can be configured
// in "webpack.config.js".
//
// Import deps with the dep name or local files with a relative path, for example:
//
// import {Socket} from "phoenix"
// import socket from "./socket"
//

import "phoenix_html"
import { Elm } from "../src/Game.elm";

var main = Elm.Game.init({
    node: document.getElementById('elm-game'),
    flags : {url: window.location.href }
});

main.ports.sendMessage.subscribe(function(message) {
    switch (message) {
        case (message.includes("?username:")):
            console.log(message.substr(10));
            sessionStorage.setItem("username", message.substr(10));
            break;
        case (message.includes("?bet:")):
            console.log(message);
            break;
    }
});