abstract class Avram::FakeParams
  include Avram::Paramable

  abstract def nested?(key : String) : Hash(String, String)

  def nested(key : String) : Hash(String, String)
    nested?(key)
  end

  def many_nested?(key : String) : Array(Hash(String, String))
    raise "Not implemented"
  end

  def many_nested(key : String) : Array(Hash(String, String))
    raise "Not implemented"
  end

  def get?(key)
    raise "Not implemented"
  end

  def get(key)
    raise "Not implemented"
  end

  def nested_file?(key)
    raise "Not implemented"
  end

  def nested_file(key)
    raise "Not implemented"
  end
end
