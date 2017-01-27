class LuckyRecord::Repo
  class_property(db_name : String) do
    raise "Must set a database name with LuckyRecord::Repo.db_name = \"name\""
  end

  def self.run
    DB.open("postgres://localhost/#{LuckyRecord::Repo.db_name}") do |db|
      yield db
    end
  end
end
