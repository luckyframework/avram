require "./spec_helper"

include LazyLoadHelpers

describe "Lazy loading associations" do
  it "can lazy load has_many and has_many through" do
    post = PostBox.create
    comment = CommentBox.new.post_id(post.id).create
    tag = TagBox.create
    tagging = TaggingBox.new.post_id(post.id).tag_id(tag.id).create

    post.comments!.should eq([comment])
    post.tags!.should eq([tag])
  end

  it "can lazy load has_one" do
    admin = AdminBox.create
    sign_in_credential = SignInCredentialBox.new.user_id(admin.id).create
    admin.sign_in_credential!.should eq(sign_in_credential)
  end

  it "can lazy load optional has_one" do
    user = UserBox.create
    user.sign_in_credential!.should be_nil
  end

  it "can lazy load belongs_to" do
    post = PostBox.create
    comment = CommentBox.new.post_id(post.id).create
    comment.post!.should eq(post)
  end

  it "can lazy load optional belongs_to" do
    employee = EmployeeBox.create
    employee.manager!.should be_nil
  end
end
