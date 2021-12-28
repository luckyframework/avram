require "../../../spec_helper"

include CleanupHelper

describe "Generating migrations" do
  it "can generate a migration with custom name" do
    with_cleanup do
      Gen::Migration.silence_output do
        ARGV.push("Should Ignore This Name")

        Gen::Migration.new.call("Custom")

        should_generate_migration named: "custom.cr"
      end
    end
  end

  it "can generate a migration with custom name and contents" do
    with_cleanup do
      Gen::Migration.silence_output do
        migrate_contents = <<-CONTENTS
        create :users do
          add name : String
        end
        CONTENTS
        rollback_contents = <<-CONTENTS
        drop :users
        CONTENTS

        Avram::Migrator::MigrationGenerator.new(
          "CreateUsers",
          migrate_contents: migrate_contents,
          rollback_contents: rollback_contents
        ).generate(_version: "123")

        File.read("./db/migrations/123_create_users.cr").should contain <<-MIGRATION
        class CreateUsers::V123 < Avram::Migrator::Migration::V1
          def migrate
            create :users do
              add name : String
            end
          end

          def rollback
            drop :users
          end
        end
        MIGRATION
      end
    end
  end
end

private def should_generate_migration(named name : String)
  Dir.new("./db/migrations").any?(&.ends_with?(name)).should be_true
end
