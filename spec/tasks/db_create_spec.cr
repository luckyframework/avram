require "../spec_helper"

describe Db::Create do
  it "raises a connection error when unable to connect" do
    Avram.temp_config(database_to_migrate: DatabaseWithIncorrectSettings) do
      expect_raises(Exception, /It looks like Postgres is not running/) do
        Db::Create.new(quiet: true).run_task
      end
    end
  end
end
