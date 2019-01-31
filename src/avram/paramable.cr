module Avram::Paramable
  abstract def nested?(key : String) : Hash(String, String)
  abstract def nested(key : String) : Hash(String, String)
  abstract def many_nested?(key : String) : Array(Hash(String, String))
  abstract def many_nested(key : String) : Array(Hash(String, String))
  abstract def get?(key : String)
  abstract def get(key : String)
end
