class Follow < BaseModel
  include Avram::SoftDelete::Model

  table do
    column soft_deleted_at : Time?

    belongs_to follower : User
    belongs_to followee : User
  end
end

class FollowQuery < Follow::BaseQuery
  include Avram::SoftDelete::Query

  def initialize
    defaults &.only_kept
  end
end
