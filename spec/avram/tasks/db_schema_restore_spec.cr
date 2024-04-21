require "../../spec_helper"

SQL_DUMP_FILE = "spec/support/files/sample_backup.sql"

describe Db::Schema::Restore do
  it "raises an error when no import file is supplied" do
    expect_raises(Exception, "A path to the import SQL file must be provided") do
      Db::Schema::Restore.new(quiet: true).run_task
    end
  end

  it "raises an error when unable to find the import file" do
    expect_raises(Exception, "Unable to locate the restore file: missing_file.sql") do
      Db::Schema::Restore.new("missing_file.sql", quiet: true).run_task
    end
  end

  it "restores from the sample_backup file" do
    swap_database_with_cleanup(SampleBackupDatabase) do
      Db::Schema::Restore.new(SQL_DUMP_FILE, quiet: true).run_task

      SampleBackupDatabase.run do |db|
        value = db.scalar("SELECT COUNT(*) FROM sample_records").as(Int64)
        value.should eq 0
      end
    end
  end
end

private def swap_database_with_cleanup(database_to_migrate, &)
  Avram.temp_config(database_to_migrate: database_to_migrate) do
    # Create this new DB
    Avram::Migrator::Runner.create_db(quiet?: true)

    yield

    # Ensure all connections to this DB are closed
    SampleBackupDatabase.close_connections!
    # make sure this is dropped before another spec runs
    Avram::Migrator::Runner.drop_db(quiet?: true)
  end
end
