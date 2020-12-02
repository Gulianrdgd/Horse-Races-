# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :horseraces,
  ecto_repos: [Horseraces.Repo]

# Configures the endpoint
config :horseraces, HorseracesWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "qfD55v/eNuQwJPFmkFygFb+Gm/rVdfXWs1CZF/PA2+8KAjUboLHqyWSh9ulVxCCs",
  render_errors: [view: HorseracesWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: Horseraces.PubSub,
  live_view: [signing_salt: "Ury0jVOt"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
