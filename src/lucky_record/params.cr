class LuckyRecord::Params
  include LuckyRecord::Paramable

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

  def nested?(key)
    @hash
  end

  def nested(key)
    @hash
  end

  def get?(key)
    @hash[key]?
  end

  def get(key)
    @hash[key]
  end
end
