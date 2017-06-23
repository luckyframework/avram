class LuckyRecord::Params
  include LuckyRecord::Paramable

  @hash : Hash(String, String)

  def initialize(@hash = Hash(String, String))
  end

  def nested(key)
    @hash
  end

  def nested!(key)
    @hash
  end

  def get(key)
    @hash[key]?
  end

  def get!(key)
    @hash[key]
  end
end
