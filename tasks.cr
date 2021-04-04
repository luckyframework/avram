require "lucky_task"
require "./src/avram"
require "./config/*"
require "./db/migrations/*"

Habitat.raise_if_missing_settings!
LuckyTask::Runner.run
