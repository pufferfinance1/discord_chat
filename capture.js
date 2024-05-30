const { fetchResults } = require('@permaweb/aoconnect');
const WebSocket = require('ws');

let cursorPosition = '';
const wsConnection = new WebSocket('ws://localhost:8080'); // Initialize WebSocket connection

wsConnection.on('open', () => {
  console.log('WebSocket connection opened');
});

wsConnection.on('error', (err) => {
  console.error('WebSocket encountered an error:', err);
});

// Function to monitor DevChat messages
async function monitorDevChat() {
  try {
    if (cursorPosition === '') {
      const initialFetch = await fetchResults({
        process: 'kRbVpOJUD19TagUPzRdew13WqkqxpzjkD0c3pMpQ0nU',
        sort: 'DESC',
        limit: 1,
      });
      cursorPosition = initialFetch.edges[0].cursor;
      console.log('Initial fetch results:', initialFetch);
    }

    console.log('Executing DevChat check...');
    const subsequentFetch = await fetchResults({
      process: '90O7RFBp7M2c9TkOot4Nb5r-rbN9QMUAmcxu0Hf3K6Q',
      from: cursorPosition,
      sort: 'ASC',
      limit: 50,
    });

    for (const item of subsequentFetch.edges.reverse()) {
      cursorPosition = item.cursor;
      console.log('Processing element data:', item.node.Messages);

      for (const msg of item.node.Messages) {
        console.log('Inspecting message tags:', msg.Tags);
      }

      const validMessages = item.node.Messages.filter(
        msg => msg.Tags.length > 0 && msg.Tags.some(tag => tag.name === 'Action' && tag.value === 'Say')
      );
      console.log('Valid messages:', validMessages);
      for (const validMsg of validMessages) {
        const eventType = validMsg.Tags.find(tag => tag.name === 'Event')?.value || 'Message in CustomRoom';
        const messageContent = `${eventType} : ${validMsg.Data}`;
        console.log('Captured message:', messageContent);
        wsConnection.send(messageContent); // Send message via WebSocket
      }
    }

  } catch (error) {
    console.error('Error during DevChat monitoring:', error);
    console.error('Detailed error:', error.message);
  } finally {
    setTimeout(monitorDevChat, 5000);
  }
}

monitorDevChat();
