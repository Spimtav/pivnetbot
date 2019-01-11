# Pivnetbot
A slack bot that assists users in pivotal network slack channels, and records information about their help requests in a Google Sheet for the project managers to keep track of.


## Intro to Slack Apps and Bots
#### Slack App Configuration
This repo implements a server to act as the backend for a slack bot.  The following is some basic background info for how a slackbot is configured.  This has already been done for PivnetBot, so most likely only small tweaks will be needed in the future.

1. A user sets up a slack app.
2. User configures the app to be a `Bot User`.  This lets the app be invited into channels like a regular user, and tells slack to only send events to the server from channels the bot is in.
3. User grants the app `OAuth Scopes`, which permit it to listen for certain kinds of events.
4. User creates a backend server to listen for events (more on this later).
5. User registers the server's URL in the app, which tells slack where to send events to for processing.
6. User subscribes the app to various Bot Events, which let it listen for any events it has permissions for.
7. (Optional) User creates `External Webhooks`, which let the server post messages into slack as the bot user.


#### Event Loop
Once the bot, app, and server have been configured, the following points outline the control flow between slack and the server.  Assume `Event X` is some event that the bot is configured to listen for.

- `Event X` occurs on a channel that the bot is in.
- Slack sends a message to the bot's server for processing.
- The server receives the message and processes it.
- (Optional) The server posts a message to the slack channel via an `External Webhook`.

That's it! Compared to the configuration steps, the actual business logic is surprisingly simple.


## PivnetBot Server Details
Now that we have context, we can talk about how PivnetBot is implemented.  There are two types of messages that pivnetbot responds to:

- Challenges: this is a special kind of message that slack sends to the URL you tell it to when performing step 5 of configuration.  The app just needs to echo back the payload that slack sends, and then the URL will be considered registered to the bot.  Other than URL registration, this payload is not used.
- Channel Messages: this is a payload that is sent to pivnetbot every time a user posts a message to a channel that pivnetbot is invited to.  It gives info about who sent the message, what channel it was sent to, the time, and the message itself.  See [this documentation page](https://api.slack.com/events/message.channels) for more info.

The latter type of message is the more interesting one.  When pivnetbot receives a message event, it scans the text of the message for any keywords that indicate that the user needs help, and if so, records information about the request in a Google Sheet for the PMs to keep track of.  Information about the user's name, the time of the message, the message itself, which keywords triggered the response, and a link to the message are recorded in the spreadsheet.


## Bot Configuration
I tried to write pivnetbot to be as modular and as extensible as possible, so all code configurations are passed in via environment variables.  If you happen to be on the pivnet team, dear reader, you can find all of the necessary configuration options in the secure document store note called `pivnet-bots`.  For those of you that aren't on the team, ~~why are you here~~ you can pass them in environment variables as usual.

All configuration options should be self explanatory, so i won't be spending time in this readme detailing them.


## Conclusion
Best of luck in supporting my creation, humans <3