FROM elixir:1.20.5-otp-29

WORKDIR /app

COPY ./ /app

RUN apt update -y && apt upgrade -y && apt install inotify-tools -y

RUN mix local.rebar --force && mix local.hex --force && mix deps.get && mix compile

CMD [ "mix", "phx.server" ]
