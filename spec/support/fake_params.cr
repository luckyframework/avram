abstract class Avram::FakeParams
  include Avram::Paramable

  abstract def nested?(key : String) : Hash(String, String)

  def nested(key : String) : Hash(String, String)
    nested?(key)
  end

  def nested_arrays?(key : String) : Hash(String, Array(String))
    raise "Not implemented"
  end

  def nested_arrays(key : String) : Hash(String, Array(String))
    raise "Not implemented"
  end

  def many_nested?(key : String) : Array(Hash(String, String))
    raise "Not implemented"
  end

  def many_nested(key : String) : Array(Hash(String, String))
    raise "Not implemented"
  end

  def get?(key) : String?
    raise "Not implemented"
  end

  def get(key) : String
    raise "Not implemented"
  end

  def get_all?(key : String) : Array(String)
    raise "Not implemented"
  end

  def get_all(key : String) : Array(String)
    raise "Not implemented"
  end

  def get_all_files?(key : String) : Array(Avram::Uploadable)
    raise "Not implemented"
  end

  def get_all_files(key : String) : Array(Avram::Uploadable)
    raise "Not implemented"
  end

  def nested_file?(key)
    raise "Not implemented"
  end

  def nested_file(key)
    raise "Not implemented"
  end

  def nested_array_files?(key : String) : Hash(String, Array(Avram::Uploadable))
    raise "Not implemented"
  end

  def nested_array_files(key : String) : Hash(String, Array(Avram::Uploadable))
    raise "Not implemented"
  end
end
