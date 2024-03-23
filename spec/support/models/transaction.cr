class Transaction < BaseModel
  include Avram::SoftDelete::Model

  enum Type
    Unknown
    Special
  end

  table do
    column type : Transaction::Type = Transaction::Type::Unknown
    column soft_deleted_at : Time?
    belongs_to user : User
  end
end

class TransactionQuery < Transaction::BaseQuery
  include Avram::SoftDelete::Query

  def initialize
    defaults &.only_kept
  end

  def special
    type(Transaction::Type::Special)
  end
end
