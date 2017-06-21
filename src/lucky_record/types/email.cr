class LuckyRecord::EmailType < LuckyRecord::Type
  alias BaseType = String

  def self.parse(value : String)
    value.downcase.strip
  end
end
