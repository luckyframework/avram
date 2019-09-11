require "../spec_helper"

SQL_DUMP_FILE = "spec/support/files/sample_backup.sql"

describe Db::Schema::Restore do
  it "raises an error when no import file is supplied" do
    expect_raises(Exception, "A path to the import SQL file must be provided") do
      Db::Schema::Restore.new.call
    end
  end

  it "raises an error when unable to find the import file" do
    expect_raises(Exception, "Unable to locate the restore file: missing_file.sql") do
      Db::Schema::Restore.new("missing_file.sql").call
    end
  end

  it "restores from the sample_backup file" do
    Avram.temp_config(database_to_migrate: SampleBackupDatabase) do
      Db::Drop.new.call
      Db::Create.new(quiet: true).call

      Db::Schema::Restore.new(SQL_DUMP_FILE).call

      SampleBackupDatabase.run do |db|
        value = db.scalar("SELECT COUNT(*) FROM sample_records").as(Int64)
        value.should eq 0
      end
    end
  end
end
