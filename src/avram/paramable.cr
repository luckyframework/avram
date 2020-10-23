module Avram::Paramable
  abstract def nested?(key : String) : Hash(String, String)
  abstract def nested(key : String) : Hash(String, String)
  abstract def get?(key : String)
  abstract def get(key : String)
  abstract def has_key_for?(operation : Avram::Operation.class | Avram::SaveOperation.class) : Bool
end
