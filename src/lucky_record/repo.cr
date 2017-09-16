class LuckyRecord::Repo
  Habitat.create do
    setting url : String
  end

  def self.run
    DB.open(settings.url) do |db|
      yield db
    end
  end
end
