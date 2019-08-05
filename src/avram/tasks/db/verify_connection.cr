class Db::VerifyConnection < LuckyCli::Task
  summary "Verify connection to postgres"
  getter? quiet

  def initialize(@quiet : Bool = false)
  end

  def call
    begin
      DB.open(Avram::Migrator::Runner.database_url) do |db|
      end
      puts "✔ Connection verified" unless quiet?
    rescue PQ::ConnectionError | DB::ConnectionRefused
      raise <<-ERROR
      Unable to connect to Postgres for database '#{Avram.settings.database_to_migrate}'.

      This is what we tried to connect to:

        * host: #{Avram::Migrator::Runner.db_host}
        * port: #{Avram::Migrator::Runner.db_port}
        * database: #{Avram::Migrator::Runner.db_name}
        * username: #{Avram::Migrator::Runner.db_user}
        * password: check config/database.cr

      To fix, try this...

        ▸ Make sure Postgres is running.
        ▸ Check connection settings in config/database.cr.
        ▸ If the database has not been created yet, run 'lucky db.create'
        ▸ Then run 'lucky db.verify_connection' to make sure it can connect.

      ERROR
    end
  end
end
