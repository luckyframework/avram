module Avram::Paramable
  abstract def nested?(key : String) : Hash(String, String)
  abstract def nested(key : String) : Hash(String, String)
  abstract def many_nested?(key : String) : Array(Hash(String, String))
  abstract def many_nested(key : String) : Array(Hash(String, String))
  abstract def get?(key : String)
  abstract def get(key : String)

  def has_key_for?(operation : Avram::Operation.class | Avram::SaveOperation.class) : Bool
    nested?(operation.param_key).any?
  end
end
