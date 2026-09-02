# Overview

**A learning project for getting used to websockets, and understanding AWS API Gateway websocket functionality.**

With this you can connect to a websocket and subscribe to 'event types'. Whenever a client sends an event it will get published to all subscribed clients.

API GW has built-in timeouts on websockets. This solution provides a way to preserve subscriptions and recover them (within a time-limit) when a connection is lost.

This project also includes a custom authorizer on the gateway. It could support API key validation, SSO token validation, or whatever mechanism you wish to implement. In this version it only expects a token with the key 'letmein'.

## Usage Examples

In this solution, clients create their own session id. A UUID is recommended, but you could append a username or other data to it for tracking and/or troubleshooting.

Use this command to connect, or to re-connect to a lost session. If re-connecting, any subscriptions that were attached to the session will remain active.
> [!NOTE]
> You could pass the token in the headers for CLI or code-based clients, but for browser support it MUST be in the query string.   
```
wscat -c "wss://<api gw stage url>$default?token=letmein&session_id=000000-0000-0000-000000"
```


Once you are connected, you can subscribe to event types:
```
{"action": "subscribe", "event_type": "<your event type name>", "session_id": "000000-0000-0000-000000"}
```

This is how to publish events:
```
{"action": "publish", "event_type": "<your event type name>", "payload": "<your data here>"}
```

## Flows
The connect flow:
![Connection flow](./Flow%20diagram%20-%20Connect.png)

The disconnect flow:
![Disconnection flow](Flow%20diagram%20-%20Disconnect.png)


