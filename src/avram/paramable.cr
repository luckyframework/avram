module Avram::Paramable
  abstract def nested?(key : String) : Hash(String, String)
  abstract def nested(key : String) : Hash(String, String)
  abstract def nested_arrays?(key : String) : Hash(String, Array(String))
  abstract def nested_arrays(key : String) : Hash(String, Array(String))
  abstract def nested_array_files?(key : String) : Hash(String, Array(Avram::Uploadable))
  abstract def nested_array_files(key : String) : Hash(String, Array(Avram::Uploadable))
  abstract def many_nested?(key : String) : Array(Hash(String, String))
  abstract def many_nested(key : String) : Array(Hash(String, String))
  abstract def get?(key : String) : String
  abstract def get(key : String) : String
  abstract def get_all?(key : String) : Array(String)
  abstract def get_all(key : String) : Array(String)
  abstract def get_all_files?(key : String) : Array(Avram::Uploadable)
  abstract def get_all_files(key : String) : Array(Avram::Uploadable)

  def has_key_for?(operation : Avram::Operation.class | Avram::SaveOperation.class) : Bool
    !nested?(operation.param_key).empty?
  end
end
