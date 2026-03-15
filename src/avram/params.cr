class Avram::Params
  include Avram::Paramable

  @hash : Hash(String, Array(String) | String) |  \
    Hash(String, Array(String)) |  \
    Hash(String, String)

  def initialize
    @hash = {} of String => String
  end

  def initialize(@hash)
  end

  def nested?(key : String) : Hash(String, String)
    nested(key)
  end

  def nested(key : String) : Hash(String, String)
    Hash(String, String).new.tap do |params|
      @hash.each do |_key, _value|
        params[_key] = _value if _value.is_a?(String)
      end
    end
  end

  def nested_arrays?(key : String) : Hash(String, Array(String))
    nested_arrays(key)
  end

  def nested_arrays(key : String) : Hash(String, Array(String))
    Hash(String, Array(String)).new.tap do |params|
      @hash.each do |_key, _value|
        params[_key] = _value if _value.is_a?(Array)
      end
    end
  end

  def many_nested?(key : String) : Array(Hash(String, String))
    many_nested(key)
  end

  def many_nested(key : String) : Array(Hash(String, String))
    [nested(key)]
  end

  def get?(key : String)
    @hash[key]?.try { |value| value if value.is_a?(String) }
  end

  def get(key : String)
    get?(key).not_nil! # ameba:disable Lint/NotNil
  end

  def get_all?(key : String)
    @hash[key]?.try { |value| value if value.is_a?(Array) }
  end

  def get_all(key : String)
    get_all?(key).not_nil! # ameba:disable Lint/NotNil
  end

  def nested_file?(key : String) : Hash(String, String)
    nested?(key)
  end

  def nested_file(key : String) : Hash(String, String)
    nested(key)
  end

  def get_all_files(key : String)
    get_all(key)
  end
end
