require "dexter"
require "lucky_cli"
require "wordsmith"
require "habitat"
require "./avram/criteria"
require "./avram/type"
require "./avram/table_for"
require "./avram/charms/**"
require "./avram/migrator/**"
require "./avram/tasks/**"
require "./avram/**"
require "db"
require "pg"
require "uuid"

module Avram
  Habitat.create do
    setting lazy_load_enabled : Bool = true
    setting logger : Dexter::Logger = Dexter::Logger.new(nil)
    setting database_to_migrate : Avram::Database
  end

  def self.logger
    settings.logger
  end
end
