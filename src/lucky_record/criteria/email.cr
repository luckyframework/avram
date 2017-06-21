require "./string"

class LuckyRecord::EmailType::Criteria(T, V) < LuckyRecord::StringType::Criteria(T, V)
  @upper = false
  @lower = false
end
