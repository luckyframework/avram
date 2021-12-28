require "../../spec_helper"

describe Db::Create do
  # This is currently failing with the wrong message.
  # it may be related to https://github.com/actions/virtual-environments/issues/4269
  pending "raises a connection error when unable to connect" do
    Avram.temp_config(database_to_migrate: DatabaseWithIncorrectSettings) do
      expect_raises(Exception, /It looks like Postgres is not running/) do
        Db::Create.new(quiet: true).run_task
      end
    end
  end
end
