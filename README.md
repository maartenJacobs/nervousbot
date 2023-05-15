# NervousBot

NervousBot is a client for spacetraders.io written in Elixir/Phoenix.

To all my past, current and future employers: this repository is not indicative of my professional work. You are basically looking at me gaming so bear that in mind.

## Setup

1. Run `asdf install` and `direnv allow`.
1. Copy `.env.example` to `.env`, filling in your details.
1. Run `mix phx.server`.

## Features

### No security

Sorry, this is a non-urgent TODO because currently all actions are taken via `iex` or on startup. If you run this app on a public server, anyone could view your stats and API logs (without secrets). Some might say that's a feature.

Most likely this will be solved by `phx.gen.auth` or HTTP basic auth in the future.

### Missions

1 basic mining mission has been implemented to automate mining for your contract's ore. The automated process will:

* Mine for ore until the ship cargo is full.
* Sell off any ore irrelevant to the contract.
* Delivery the relevant ore to the contract waypoint.

These guarantees are provided if you've accepted the contract, have enough credits to refuel and the ship is currently at a mining waypoint. In the near future the process might be able to calibrate itself, e.g. navigate to a mining waypoint.

### Dashboard

`/dashboard` shows your credits, recent API logs and the state of your current contracts. If you have a mission running, the dashboard updates automatically. API logs are refreshed every second as well.

## Release

Run the following.

```bash
mix deps.get --only prod && MIX_ENV=prod mix do compile, assets.deploy, phx.gen.release, release
```

Then scp to your server. The release can then be started with the `server` command.

Missions need to be started separately using the `rpc 'NervousBotMissions.Missions.start_missions!()'` command.

TODO: use Docker instead to avoid SSH.
