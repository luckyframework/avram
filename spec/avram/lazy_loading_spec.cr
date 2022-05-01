require "../spec_helper"

include LazyLoadHelpers

describe "Lazy loading associations" do
  it "can lazy load has_many and has_many through" do
    post = PostFactory.create
    comment = CommentFactory.new.post_id(post.id).create
    tag = TagFactory.create
    TaggingFactory.new.post_id(post.id).tag_id(tag.id).create

    post.comments!.should eq([comment])
    post.tags!.should eq([tag])
  end

  it "can lazy load has_one" do
    # to verify it is loading the correct association, not just the first
    SignInCredentialFactory.new.user_id(AdminFactory.create.id).create

    admin = AdminFactory.create
    sign_in_credential = SignInCredentialFactory.new.user_id(admin.id).create
    admin.sign_in_credential!.should eq(sign_in_credential)
  end

  it "can lazy load optional has_one" do
    user = UserFactory.create
    user.sign_in_credential!.should be_nil
  end

  it "can lazy load belongs_to" do
    post = PostFactory.create
    comment = CommentFactory.new.post_id(post.id).create
    comment.post!.should eq(post)
  end

  it "can lazy load optional belongs_to" do
    employee = EmployeeFactory.create
    employee.manager!.should be_nil
  end
end
