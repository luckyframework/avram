require "../../../spec_helper"

include CleanupHelper

describe "Generating migrations" do
  it "can generate a migration with custom name" do
    with_cleanup do
      task = Gen::Migration.new
      task.output = IO::Memory.new
      task.print_help_or_call(args: ["Custom"])

      should_generate_migration named: "custom.cr"
    end
  end

  it "can generate a migration with custom name and contents" do
    with_cleanup do
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
        io: IO::Memory.new,
        migrate_contents: migrate_contents,
        rollback_contents: rollback_contents
      ).generate(_version: "123")

      created_migration_file = File.read("./db/migrations/123_create_users.cr")
      created_migration_file.should contain <<-MIGRATION
      class CreateUsers::V123 < Avram::Migrator::Migration::V1
        def migrate
          create :users do
            add name : String
          end
        end
      MIGRATION
      # HACK: This is broken up because on Windows everything is returning \r\n except for
      # the empty line which is just returning \n
      created_migration_file.should contain <<-MIGRATION
        def rollback
          drop :users
        end
      end
      MIGRATION
    end
  end
end

private def should_generate_migration(named name : String)
  Dir.new("./db/migrations").any?(&.ends_with?(name)).should be_true
end
