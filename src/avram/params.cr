class Avram::Params
  include Avram::Paramable

  @hash : Hash(String, Array(String)) = {} of String => Array(String)

  def initialize
  end

  def initialize(@hash)
  end

  def nested?(key : String) : Hash(String, String)
    nested(key)
  end

  def nested(key : String) : Hash(String, String)
    Hash(String, String).new.tap do |h|
      @hash.each do |k, v|
        h[k] = v.first?.to_s
      end
    end
  end

  def nested_arrays?(key : String) : Hash(String, Array(String))
    nested_arrays(key)
  end

  def nested_arrays(key : String) : Hash(String, Array(String))
    @hash
  end

  def many_nested?(key : String) : Array(Hash(String, String))
    many_nested(key)
  end

  def many_nested(key : String) : Array(Hash(String, String))
    [nested(key)]
  end

  def get?(key : String)
    @hash[key]?.try(&.first?)
  end

  def get(key : String)
    @hash[key].first
  end

  def get_all?(key : String)
    @hash[key]? || [] of String
  end

  def get_all(key : String)
    @hash[key]
  end

  def get_all_files?(key : String)
    get_all_files(key)
  end

  def get_all_files(key : String)
    @hash[key]
  end

  def nested_file?(key : String) : Hash(String, String)
    nested?(key)
  end

  def nested_file(key : String) : Hash(String, String)
    nested(key)
  end
end
