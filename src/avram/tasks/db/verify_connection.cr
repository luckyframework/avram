class Db::VerifyConnection < LuckyCli::Task
  summary "Verify connection to postgres"

  def call
    begin
      DB.open(Avram::Migrator::Runner.database_url) do |db|
      end
    rescue PQ::ConnectionError | DB::ConnectionRefused
      raise <<-ERROR
      Unable to connect to Postgres for database '#{Avram.settings.database_to_migrate}'.

      This is what we tried to connect to:

        * host: #{Avram::Migrator::Runner.db_host}
        * database: #{Avram::Migrator::Runner.db_name}
        * username: #{Avram::Migrator::Runner.db_user}
        * password: check config/database.cr

      To fix, try this...

        ▸ Make sure Postgres is running.
        ▸ Check your database config in config/database.cr and make sure it is correct.
        ▸ Then run `lucky db.verify_connection` to make sure it can connect.

      ERROR
    end
  end
end
