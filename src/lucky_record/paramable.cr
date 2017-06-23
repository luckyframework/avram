module LuckyRecord::Paramable
  abstract def nested(key) : Hash(String, String)
  abstract def nested!(key) : Hash(String, String)
  abstract def get(key)
  abstract def get!(key)
end
