module Lucky::Paramable
  abstract def nested?(key : String) : Hash(String, String)
  abstract def nested(key : String) : Hash(String, String)
  abstract def nested_arrays?(key : String) : Hash(String, Array(String))
  abstract def nested_arrays(key : String) : Hash(String, Array(String))
  abstract def many_nested?(key : String) : Array(Hash(String, String))
  abstract def many_nested(key : String) : Array(Hash(String, String))
  abstract def get?(key : String)
  abstract def get(key : String)
  abstract def get_all?(key : String)
  abstract def get_all(key : String)

  def has_key_for?(operation : Lucky::BaseOperation.class) : Bool
    !nested?(operation.param_key).empty?
  end
end