# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :libcluster, debug: true

config :payment_backend, Oban,
  engine: Oban.Engines.Basic,
  notifier: Oban.Notifiers.Postgres,
  queues: [create_payment: 20, create_payment_with_health_service: 20],
  repo: PaymentBackend.Repo

config :payment_backend, PaymentBackend.Oban, repo: PaymentBackend.Repo

config :payment_backend,
  ecto_repos: [PaymentBackend.Repo],
  generators: [timestamp_type: :utc_datetime]

# Configures the endpoint
config :payment_backend, PaymentBackendWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [html: PaymentBackendWeb.ErrorHTML, json: PaymentBackendWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: PaymentBackend.PubSub,
  live_view: [signing_salt: "rqihLWIA"]

# Configures the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.
config :payment_backend, PaymentBackend.Mailer, adapter: Swoosh.Adapters.Local

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.17.11",
  payment_backend: [
    args:
      ~w(js/app.js --bundle --target=es2017 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

# Configure tailwind (the version is required)
config :tailwind,
  version: "3.4.3",
  payment_backend: [
    args: ~w(
      --config=tailwind.config.js
      --input=css/app.css
      --output=../priv/static/assets/app.css
    ),
    cd: Path.expand("../assets", __DIR__)
  ]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Nebulex cache configuration
config :payment_backend, PaymentBackend.ReplicatedCache,
  primary: [
    gc_interval: 3_600_000,
    allocated_memory: 25_165_824
  ]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
