require "../../spec_helper"

describe Avram::Migrator::Runner do
  describe "setup_migration_tracking_table" do
    it "includes a unique index" do
      Avram.temp_config(database_to_migrate: TestDatabase) do
        Avram::Migrator::Runner.setup_migration_tracking_tables

        results = TestDatabase.query_all("SELECT indexname FROM pg_catalog.pg_indexes WHERE tablename = 'migrations'", as: String)
        results.should contain("migrations_version_index")
      end
    end
  end

  describe ".create_db" do
    context "when the DB doesn't exist yet" do
      it "creates the new DB" do
        Avram.temp_config(database_to_migrate: SampleBackupDatabase) do
          Avram::Migrator::Runner.create_db(quiet: true)

          DB.open(SampleBackupDatabase.credentials.url) do |db|
            results = db.query_all("SELECT datname FROM pg_database WHERE datistemplate = false", as: String)
            results.should contain("sample_backup")
          end
          # ensure it's deleted before moving on to another spec
          Avram::Migrator::Runner.drop_db(quiet: true)
        end
      end
    end
  end

  describe ".drop_db" do
    context "when it already exists" do
      it "drops the DB" do
        Avram.temp_config(database_to_migrate: SampleBackupDatabase) do
          Avram::Migrator::Runner.create_db(quiet: true)
          Avram::Migrator::Runner.drop_db(quiet: true)

          expect_raises(DB::ConnectionRefused) do
            DB.open(SampleBackupDatabase.credentials.url) do |_|
            end
          end
        end
      end
    end
  end
end
