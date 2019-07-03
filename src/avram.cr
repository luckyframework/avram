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
  def self.logger
    Avram::Repo.settings.logger
  end
end
