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
end
