require "shell-table"

class Db::Migrations::Status < BaseTask
  summary "Print the current status of migrations"

  def run_task
    if migrations.none?
      puts "There are no migrations.".colorize(:green)
    else
      ensure_migration_tracking_tables_exist
      print_migration_statuses
    end
  end

  def help_message
    <<-TEXT
    Shows which migrations are pending and which have been run.

    Examples:

      lucky db.migrations.status
      LUCKY_ENV=test lucky db.migrations.status # Show migration status for test db

    TEXT
  end

  private def migrations
    Avram::Migrator::Runner.migrations
  end

  private def ensure_migration_tracking_tables_exist
    Avram::Migrator::Runner.setup_migration_tracking_tables
  end

  private def print_migration_statuses
    puts ShellTable.new(
      labels: ["Migration", "Status"],
      label_color: :white,
      rows: migration_statuses
    )
  end

  private def migration_statuses
    migrations.map do |migration|
      status = migration.new.migrated? ? "Migrated" : "Pending".colorize(:yellow)
      [migration.name, status]
    end
  end
end
