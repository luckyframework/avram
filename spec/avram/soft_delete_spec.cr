require "../spec_helper"

class SoftDeletableItemQuery < SoftDeletableItem::BaseQuery
  include Avram::SoftDelete::Query
end

describe "Avram soft delete" do
  describe "models" do
    it "allows soft deleting a record" do
      item = SoftDeletableItemFactory.create &.kept

      item = item.soft_delete

      item.soft_deleted_at.should_not be_nil
    end

    it "allows restoring a soft deleted record" do
      item = SoftDeletableItemFactory.create &.soft_deleted

      item = item.restore

      item.soft_deleted_at.should be_nil
    end

    it "allows checking if a record is soft deleted" do
      item = SoftDeletableItemFactory.create &.kept
      item.soft_deleted?.should be_false

      item = item.soft_delete

      item.soft_deleted?.should be_true
    end
  end

  describe "queries" do
    it "can get only kept records" do
      kept_item = SoftDeletableItemFactory.create &.kept
      SoftDeletableItemFactory.create &.soft_deleted

      SoftDeletableItemQuery.new.only_soft_deleted.only_kept.results.should eq([
        kept_item,
      ])
    end

    it "can get only soft deleted records" do
      SoftDeletableItemFactory.create &.kept
      soft_deleted_item = SoftDeletableItemFactory.create &.soft_deleted

      SoftDeletableItemQuery.new.only_kept.only_soft_deleted.results.should eq([
        soft_deleted_item,
      ])
    end

    it "can get soft deleted and kept records" do
      kept_item = SoftDeletableItemFactory.create &.kept
      soft_deleted_item = SoftDeletableItemFactory.create &.soft_deleted

      SoftDeletableItemQuery.new.only_kept.with_soft_deleted.results.should eq([
        kept_item,
        soft_deleted_item,
      ])
    end

    it "can bulk soft delete" do
      kept_item = SoftDeletableItemFactory.create &.kept
      soft_deleted_item = SoftDeletableItemFactory.create &.soft_deleted

      num_restored = SoftDeletableItemQuery.new.soft_delete

      num_restored.should eq(1)
      kept_item.reload.soft_deleted?.should be_true
      soft_deleted_item.reload.soft_deleted?.should be_true
    end

    it "can bulk restore" do
      kept_item = SoftDeletableItemFactory.create &.kept
      soft_deleted_item = SoftDeletableItemFactory.create &.soft_deleted

      num_restored = SoftDeletableItemQuery.new.restore

      num_restored.should eq(1)
      kept_item.reload.soft_deleted?.should be_false
      soft_deleted_item.reload.soft_deleted?.should be_false
    end
  end
end

private def reload(item)
  SoftDeletableItemQuery.find(item.id)
end
