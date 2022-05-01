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
end
