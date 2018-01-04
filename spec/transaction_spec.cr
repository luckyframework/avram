require "./spec_helper"

private class PostTransactionForm < Post::BaseForm
  allow title
  needs rollback_after_save : Bool

  def after_save(_user)
    if rollback_after_save
      LuckyRecord::Repo.rollback
    end
  end
end

private class BadForm < Post::BaseForm
  allow title

  def after_save(_user)
    raise "Sad face"
  end
end

describe "LuckyRecord::Form" do
  describe "wrapping multiple saves in a transaction" do
    it "rolls them all back" do
      LuckyRecord::Repo.transaction do
        UserBox.save
        PostBox.save
        LuckyRecord::Repo.rollback
      end

      UserQuery.new.count.to_i.should eq(0)
      Post::BaseQuery.new.count.to_i.should eq(0)
    end
  end

  describe "updating" do
    it "runs in a transaction" do
      params = {"title" => "New Title"}
      post = PostBox.new.title("Old Title").save
      Post::BaseQuery.new.first.title.should eq "Old Title"

      PostTransactionForm.update(post, params, rollback_after_save: true) do |form, post|
        Post::BaseQuery.new.first.title.should eq "Old Title"
        form.saved?.should be_false
      end

      PostTransactionForm.update(post, params, rollback_after_save: false) do |form, post|
        Post::BaseQuery.new.first.title.should eq "New Title"
        form.saved?.should be_true
      end
    end
  end

  describe "creating" do
    it "runs in a transaction" do
      params = {"title" => "New Title"}
      PostTransactionForm.create(params, rollback_after_save: true) do |form, post|
        Post::BaseQuery.new.count.to_i.should eq(0)
        post.should be_nil
        form.saved?.should be_false
      end

      PostTransactionForm.create(params, rollback_after_save: false) do |form, post|
        Post::BaseQuery.new.count.to_i.should eq(1)
        post.should_not be_nil
        form.saved?.should be_true
      end
    end
  end

  describe "raising an error" do
    it "rolls back the transaction and re-raises the error" do
      params = {"title" => "New Title"}
      expect_raises Exception, "Sad face" do
        BadForm.create(params) do |form, post|
          raise "This should not be executed"
        end
      end
      Post::BaseQuery.new.count.to_i.should eq(0)
    end
  end
end
