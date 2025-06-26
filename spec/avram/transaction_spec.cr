require "../spec_helper"

include ParamHelper

private class PostTransactionSaveOperation < Post::SaveOperation
  permit_columns title
  needs rollback_after_save : Bool

  def after_save(_user)
    if rollback_after_save
      TestDatabase.rollback
    end
  end
end

private class BadSaveOperation < Post::SaveOperation
  permit_columns title

  def after_save(_user)
    raise "Sad face"
  end
end

describe "Avram::SaveOperation" do
  describe "wrapping multiple saves in a transaction" do
    it "rolls them all back" do
      TestDatabase.transaction do
        UserFactory.create
        PostFactory.create
        TestDatabase.rollback
      end.should be_false

      UserQuery.new.select_count.to_i.should eq(0)
      Post::BaseQuery.new.select_count.to_i.should eq(0)
    end
  end

  describe "updating" do
    it "runs in a transaction" do
      params = build_params("post:title=New Title")
      post = PostFactory.new.title("Old Title").create
      Post::BaseQuery.new.first.title.should eq "Old Title"

      PostTransactionSaveOperation.update(post, params, rollback_after_save: true) do |operation, _post|
        Post::BaseQuery.new.first.title.should eq "Old Title"
        operation.saved?.should be_false
      end

      PostTransactionSaveOperation.update(post, params, rollback_after_save: false) do |operation, _post|
        Post::BaseQuery.new.first.title.should eq "New Title"
        operation.saved?.should be_true
      end
    end
  end

  describe "creating" do
    it "runs in a transaction" do
      params = build_params("post:title=New Title")
      PostTransactionSaveOperation.create(params, rollback_after_save: true) do |operation, post|
        Post::BaseQuery.new.select_count.to_i.should eq(0)
        post.should be_nil
        operation.saved?.should be_false
      end

      PostTransactionSaveOperation.create(params, rollback_after_save: false) do |operation, post|
        Post::BaseQuery.new.select_count.to_i.should eq(1)
        post.should_not be_nil
        operation.saved?.should be_true
      end
    end

    it "releases connection after operation finishes and no transactions open", tags: Avram::SpecHelper::TRUNCATE do
      PostTransactionSaveOperation.create!(title: "New Title", rollback_after_save: false)
      TestDatabase.connections.should be_empty
    end
  end

  describe "raising an error" do
    it "rolls back the transaction and re-raises the error" do
      params = build_params("post:title=New Title")
      expect_raises Exception, "Sad face" do
        BadSaveOperation.create(params) do |_operation, _post|
          raise "This should not be executed"
        end
      end
      Post::BaseQuery.new.select_count.to_i.should eq(0)
    end
  end
end
