FROM hexpm/elixir:1.12.2-erlang-24.1.4-alpine-3.13.6 as build

RUN apk update && apk add bash
RUN apk add --update nodejs nodejs-npm

RUN mkdir /app
WORKDIR /app

COPY . .

ARG REACT_APP_API_BASE
ARG REACT_APP_WS_BASE
RUN npm --prefix /app/client ci
RUN npm --prefix /app/client run build

RUN mix local.hex --force && \
    mix local.rebar --force

RUN export MIX_ENV=prod && \
    rm -Rf _build && \
    mix deps.get && \
    mix release

RUN ln -s /app/_build/prod/rel/websocket_playground/bin/websocket_playground /app/app

RUN chmod +x /app/docker-start.sh
CMD ["/app/docker-start.sh"]