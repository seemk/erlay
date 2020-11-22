import Config

if config_env() == :prod do
  config :erlay, :address, "10.0.0.4"
end
