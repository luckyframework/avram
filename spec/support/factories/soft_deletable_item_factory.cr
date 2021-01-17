class SoftDeletableItemFactory < BaseFactory
  def kept
    soft_deleted_at nil
  end

  def soft_deleted
    soft_deleted_at Time.utc
  end
end
