FROM hexpm/elixir:1.12.2-erlang-24.1.4-alpine-3.13.6 as build

RUN apk update && apk add bash
RUN apk add --update nodejs nodejs-npm

ARG DB_HOST
ARG DB_PASSWORD
ARG DB_NAME
ARG DB_HOST
ARG DB_PORT
RUN printenv

RUN mkdir /app
WORKDIR /app


COPY . .

RUN cd client && npm ci && npm run build

RUN mix local.hex --force && \
    mix local.rebar --force

ARG DB_HOST
# TODO REMOVE
RUN printenv

RUN export MIX_ENV=prod && \
    rm -Rf _build && \
    mix deps.get && \
    mix release

RUN chmod +x /app/docker-start.sh
CMD ["/app/docker-start.sh"]