#!/usr/bin/env bash

npm --prefix /app/client ci
npm --prefix /app/client run build

/app/_build/prod/rel/websocket_playground/bin/websocket_playground eval "WebsocketPlayground.Release.migrate"
/app_build/prod/rel/websocket_playground/bin/websocket_playground start