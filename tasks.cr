require "lucky_cli"
require "./src/avram"
require "./config/*"
require "./db/migrations/*"

Habitat.raise_if_missing_settings!
LuckyCli::Runner.run
