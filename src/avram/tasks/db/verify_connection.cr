class Db::VerifyConnection < LuckyCli::Task
  summary "Verify connection to postgres"

  def call
    begin
      DB.open(Avram::Migrator::Runner.database_url) do |db|
      end
    rescue PQ::ConnectionError | DB::ConnectionRefused
      raise <<-ERROR
      Unable to connect to postgres.

      Try this...

        ▸ Check your configuration in config/database.cr
        ▸ Ensure you can connect locally using `psql #{Avram::Migrator::Runner.cmd_args}`

      ERROR
    end
  end
end
