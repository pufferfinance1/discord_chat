const { Client, GatewayIntentBits } = require('discord.js');
const WebSocket = require('ws');
const { message, createDataItemSigner } = require('@permaweb/aoconnect');
const { readFileSync } = require('fs');

const token = 'MTI0NTY0NDc1MjI1OTM4NzQxNA.GHCxlL.JaC87CKMh4Lszy8qmBeN1WFN0VhJ4-qhNfJ7Lc';
const channelId = '1245647156061274113';
const walletPath = '/root/.aos.json';
const walletContent = JSON.parse(readFileSync(walletPath, 'utf-8'));

async function sendToDevChat(discordMessage) {
  const author = discordMessage.author.username;
  const content = discordMessage.content;

  console.log(`Sending message from ${author} to DevChat`);

  try {
    const response = await message({
      process: 'kRbVpOJUD19TagUPzRdew13WqkqxpzjkD0c3pMpQ0nU',
      tags: [
        { name: 'Action', value: 'TransferToDevChat' },
        { name: 'Content', value: content },
        { name: 'Sender', value: author },
      ],
      signer: createDataItemSigner(walletContent),
      data: content,
    });
    console.log('Message successfully sent to DevChat:', response);
  } catch (error) {
    console.error('Error sending message to DevChat:', error);
  }
}

const client = new Client({
  intents: [
    GatewayIntentBits.Guilds,
    GatewayIntentBits.GuildMessages,
    GatewayIntentBits.MessageContent,
  ]
});

client.once('ready', () => {
  console.log(`Logged in as ${client.user.tag}!`);
  setupWebSocketServer();
});

client.login(token);

function setupWebSocketServer() {
  const server = new WebSocket.Server({ port: 8080 });

  server.on('connection', socket => {
    console.log('WebSocket connection established');

    socket.on('message', async (message) => {
      const text = message.toString();
      console.log('Received message:', text);
      const channel = client.channels.cache.get(channelId);
      if (channel) {
        try {
          await channel.send(text);
          console.log('Message sent to Discord');
          await sendToDevChat({ author: { username: 'DiscordUser' }, content: text });
        } catch (error) {
          console.error('Error relaying message:', error);
        }
      } else {
        console.error('Discord channel not found.');
      }
    });

    socket.on('close', () => {
      console.log('WebSocket connection closed');
    });
  });

  console.log('WebSocket server is running on port 8080');
}

client.on('messageCreate', message => {
  console.log(`New message from ${message.author.username}: ${message.content}`);
  sendToDevChat(message);
});
