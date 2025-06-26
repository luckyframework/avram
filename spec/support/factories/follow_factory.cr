class FollowFactory < BaseFactory
  def initialize
    before_save do
      if operation.follower_id.value.nil?
        follower(UserFactory.create)
      end
      if operation.followee_id.value.nil?
        followee(UserFactory.create)
      end
    end
  end

  def follower(u : User)
    follower_id(u.id)
  end

  def followee(u : User)
    followee_id(u.id)
  end
end
