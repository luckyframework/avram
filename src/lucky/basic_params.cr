class Lucky::BasicParams
  include Lucky::Paramable

  @hash : Hash(String, Array(String) | String) |
    Hash(String, Array(String)) |
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
    get?(key) || ""
  end

  def get_all?(key : String) : Array(String)
    value = @hash[key]?
    case value
    when Array(String)
      value
    when String
      [value]
    else
      [] of String
    end
  end

  def get_all(key : String) : Array(String)
    get_all?(key)
  end
end