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
//     import {Socket} from "phoenix"
//     import socket from "./socket"
//
import "phoenix_html"
import { Elm } from "../src/Main.elm";

var app = Elm.Main.init({
    node: document.getElementById('elm-main'),
    flags : {url: window.location.href }
});

app.ports.sendMessage.subscribe(function(message) {
    if(message.includes("?username:")){
        console.log(message.substr(10));
        sessionStorage.setItem("username", message.substr( 10));
    }
});