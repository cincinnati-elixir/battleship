use Mix.Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :battleship_web, BattleshipWeb.Endpoint,
  http: [port: 4002],
  server: false
