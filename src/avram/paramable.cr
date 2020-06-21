module Avram::Paramable
  abstract def nested?(key : String) : Hash(String, String)
  abstract def nested(key : String) : Hash(String, String)
  abstract def get?(key : String)
  abstract def get(key : String)
  abstract def nested_file?(key : String)
  abstract def nested_file(key : String)
end
