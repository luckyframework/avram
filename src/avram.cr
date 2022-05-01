require "dexter"
require "wordsmith"
require "habitat"
require "pulsar"
require "lucky_cache"
require "db"
require "pg"
require "uuid"
require "cadmium_transliterator"

require "./ext/db/*"
require "./avram/object_extensions"
require "./avram/criteria"
require "./avram/type"
require "./avram/table_for"
require "./avram/criteria_extensions/*"
require "./avram/charms/**"
require "./avram/migrator/**"
require "./avram/tasks/**"
require "./avram/**"

module Avram
  Habitat.create do
    setting lazy_load_enabled : Bool = true
    setting database_to_migrate : Avram::Database.class, example: "AppDatabase"
    setting time_formats : Array(String) = [] of String
    setting i18n_backend : Avram::I18nBackend = Avram::I18n.new, example: "Avram::I18n.new"
    setting query_cache_enabled : Bool = false
  end

  Log            = ::Log.for(Avram)
  QueryLog       = Log.for("query")
  FailedQueryLog = Log.for("failed_query")
  SaveFailedLog  = Log.for("save_failed")

  alias TableName = String | Symbol

  def self.initialize_logging
    Avram::Events::QueryEvent.subscribe do |event, duration|
      next if event.query.starts_with?("TRUNCATE")

      Avram::QueryLog.dexter.info do
        queryable = event.queryable
        log_data = {
          query:    event.query,
          args:     event.args,
          duration: Pulsar.elapsed_text(duration),
        }

        if queryable
          {model: queryable}.merge(log_data)
        else
          log_data
        end
      end
    end

    Avram::Events::FailedQueryEvent.subscribe do |event|
      Avram::FailedQueryLog.dexter.error do
        queryable = event.queryable
        log_data = {
          error_message: event.error_message,
          query:         event.query,
          args:          "[FILTERED]",
        }

        if queryable
          {model: queryable}.merge(log_data)
        else
          log_data
        end
      end
    end

    Avram::Events::SaveFailedEvent.subscribe do |event|
      Avram::SaveFailedLog.dexter.warn do
        {
          failed_to_save:    event.operation_class,
          validation_errors: event.error_messages_as_string,
        }
      end
    end
  end
end

Avram.initialize_logging
