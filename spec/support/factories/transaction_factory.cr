class TransactionFactory < BaseFactory
  def initialize
    before_save do
      if operation.user_id.value.nil?
        user(UserFactory.create)
      end
    end
  end

  def user(u : User)
    user_id(u.id)
  end
end
