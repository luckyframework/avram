class LuckyRecord::Repo
  @@db : DB::Database? = nil

  Habitat.create do
    setting url : String
  end

  def self.run
    yield db
  end

  def self.db
    @@db ||= DB.open(settings.url)
  end

  def self.truncate
    DatabaseCleaner.new.truncate
  end

  class DatabaseCleaner
    def truncate
      return if table_names.empty?
      statement = ("TRUNCATE TABLE #{table_names.map { |name| name }.join(", ")} RESTART IDENTITY CASCADE;")
      LuckyRecord::Repo.run do |db|
        db.exec statement
      end
    end

    def table_names
      tables_with_schema(excluding: "schema_migrations")
    end

    def tables_with_schema(excluding : String)
      select_rows <<-SQL
      SELECT table_name
      FROM information_schema.tables
      WHERE table_schema='public'
      AND table_type='BASE TABLE'
      AND table_name != '#{excluding}';
      SQL
    end

    def select_rows(statement)
      rows = [] of String

      LuckyRecord::Repo.run do |db|
        db.query statement do |rs|
          rs.each do
            rows << rs.read(String)
          end
        end
      end

      rows
    end
  end
end
