class Avram::Params
  include Avram::Paramable

  @hash : Hash(String, String) = {} of String => String

  def initialize
  end

  def initialize(@hash)
  end

  def initialize(**args)
    args.each do |key, value|
      @hash[key.to_s] = value.to_s
    end
  end

  def nested?(key) : Hash(String, String)
    @hash
  end

  def nested(key) : Hash(String, String)
    @hash
  end

  def many_nested?(key) : Array(Hash(String, String))
    [nested?(key)]
  end

  def many_nested(key) : Array(Hash(String, String))
    [nested(key)]
  end

  def get?(key)
    @hash[key]?
  end

  def get(key)
    @hash[key]
  end

  def nested_file?(key) : Hash(String, String)
    @hash
  end

  def nested_file(key) : Hash(String, String)
    @hash
  end
end
