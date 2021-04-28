import tmi, { ChatUserstate } from 'tmi.js';
import {getTrackIdFromLink, SPOTIFY_LINK_START} from './messageUtils';
import SpotifyService from './spotify.service';
import { TWITCH_CHANNEL, COMMAND_PREFIX } from './config.json';

const fetch = require('node-fetch');

let twitchClient : any = undefined;

export default class TwitchService {
  constructor() {
    
  }

  public async connectToChat() {
    const twitchOptions = {
      channels: [TWITCH_CHANNEL],
      identity: {
        username: "codespells",
        password: process.env["OAUTH_TOKEN"]
    }
    };
    twitchClient = tmi.client(twitchOptions);

    twitchClient.on('connected', (_addr: string, _port: number) =>
      console.log(`Connected to ${TWITCH_CHANNEL}'s chat`)
    );

    twitchClient.on(
      'message',
      async (
        target: string,
        userState: ChatUserstate,
        msg: string,
        self: boolean
      ) => await this.handleMessage(target, userState, msg, self)
    );

    await twitchClient.connect();
  }

  private async handleMessage(
    _target: string,
    _userState: ChatUserstate,
    msg: string,
    self: boolean
  ) {
    if (self) {
      return;
    }
    if (msg.startsWith("!!")) {
      console.log('>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>');
      msg = "(" + msg.substring(`!!`.length) + ")";
      console.log('Command: ', msg);
      fetch("http://localhost:8081/twitch-spell?spell=" + encodeURIComponent(msg)
            + "&twitch-id=" + _userState.username)
      .then((r : any)=>r.json())
      .then((r : any)=>{twitchClient.say(_target, r.value)});
      console.log('<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<');
    }
  }
}
