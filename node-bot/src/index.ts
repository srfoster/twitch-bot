import TwitchService from './twitch.service';

require('dotenv').config()

const express = require('express')
const app = express();

//To avoid starting up if we are already running,
// Also to give the option to take calls from Racket later.
var listener = app.listen(39395, function() {
  
});

const twitchService = new TwitchService();
twitchService.connectToChat();