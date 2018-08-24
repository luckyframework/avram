module LuckyRecord::Migrator
  def self.run
    yield
  rescue e : PQ::PQError
    raise e.message.colorize(:red).to_s
  rescue e : Exception
    raise e.message.to_s
  end
end
