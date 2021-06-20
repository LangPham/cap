import Config

config :cap,
       effect: :deny,
       policy: %{}

config :phoenix, :json_library, Jason