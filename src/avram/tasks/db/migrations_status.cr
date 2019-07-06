require "shell-table"

class Db::Migrations::Status < LuckyCli::Task
  summary "Print the current status of migrations"

  def call
    if migrations.none?
      puts "There are no migrations.".colorize(:green)
    else
      ensure_migration_tracking_tables_exist
      print_migration_statuses
    end
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
      status = migration.new.migrated? ? "Migrated" : "Pending"
      [migration.name, status]
    end
  end
end
