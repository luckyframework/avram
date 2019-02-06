require "./spec_helper"

include LazyLoadHelpers

describe "Preloading" do
  it "can disable lazy loading" do
    with_lazy_load(enabled: false) do
      post = PostBox.create

      posts = Post::BaseQuery.new

      expect_raises Avram::LazyLoadError do
        posts.first.comments
      end
    end
  end

  it "preloads has_one" do
    with_lazy_load(enabled: false) do
      admin = AdminBox.create
      sign_in_credential = SignInCredentialBox.create &.user_id(admin.id)

      admin = Admin::BaseQuery.new.preload_sign_in_credential

      admin.first.sign_in_credential.should eq sign_in_credential
    end
  end

  it "preloads has_one with custom query and nested preload" do
    with_lazy_load(enabled: false) do
      user = UserBox.create
      sign_in_credential = SignInCredentialBox.create &.user_id(user.id)

      user = User::BaseQuery.new.preload(
        SignInCredential::BaseQuery.new.preload_user
      ).first

      user.sign_in_credential.not_nil!.user.should eq user
    end
  end

  it "preloads optional has_one" do
    with_lazy_load(enabled: false) do
      user = UserBox.create
      user = User::BaseQuery.new.preload_sign_in_credential.first
      user.sign_in_credential.should be_nil

      sign_in_credential = SignInCredentialBox.new.user_id(user.id).create
      user = User::BaseQuery.new.preload_sign_in_credential.first
      user.sign_in_credential.should eq sign_in_credential
    end
  end

  it "preloads has_many" do
    with_lazy_load(enabled: false) do
      post = PostBox.create
      comment = CommentBox.create &.post_id(post.id)

      posts = Post::BaseQuery.new.preload_comments

      posts.results.first.comments.should eq([comment])
    end
  end

  it "preloads has_many with custom query" do
    with_lazy_load(enabled: false) do
      post = PostBox.create
      comment = CommentBox.create &.post_id(post.id)

      posts = Post::BaseQuery.new.preload(
        Comment::BaseQuery.new.id.not.eq(comment.id)
      )

      posts.results.first.comments.should eq([] of Comment)
    end
  end

  it "preloads has_many through" do
    with_lazy_load(enabled: false) do
      tag = TagBox.create
      _unused_tag = TagBox.create
      post = PostBox.create
      other_post = PostBox.create
      TaggingBox.create &.tag_id(tag.id).post_id(post.id)
      TaggingBox.create &.tag_id(tag.id).post_id(other_post.id)

      post_tags = Post::BaseQuery.new.preload_tags.results.first.tags

      post_tags.size.should eq(1)
      post_tags.should eq([tag])
    end
  end

  it "preloads has_many through with uuids" do
    with_lazy_load(enabled: false) do
      item = LineItemBox.create
      other_item = LineItemBox.create
      product = ProductBox.create
      _unused_product = ProductBox.create
      LineItemProductBox.create &.line_item_id(item.id).product_id(product.id)
      LineItemProductBox.create &.line_item_id(other_item.id).product_id(product.id)

      item_products = LineItemQuery.new.preload_products.results.first.products

      item_products.size.should eq(1)
      item_products.should eq([product])
    end
  end

  it "preloads uuid backed has_many" do
    with_lazy_load(enabled: false) do
      item = LineItemBox.create
      scan = ScanBox.create &.line_item_id(item.id)

      items = LineItem::BaseQuery.new.preload_scans

      items.results.first.scans.should eq([scan])
    end
  end

  it "works with nested preloads" do
    with_lazy_load(enabled: false) do
      post = PostBox.create
      comment = CommentBox.create &.post_id(post.id)

      posts = Post::BaseQuery.new.preload(
        Comment::BaseQuery.new.preload_post
      )

      posts.first.comments.first.post.should eq(post)
    end
  end

  it "uses an empty array if there are no associated records" do
    with_lazy_load(enabled: false) do
      post = PostBox.create

      posts = Post::BaseQuery.new.preload_comments

      posts.results.first.comments.should eq([] of Comment)
    end
  end

  it "preloads belongs_to" do
    with_lazy_load(enabled: false) do
      post = PostBox.create
      comment = CommentBox.create &.post_id(post.id)

      comments = Comment::BaseQuery.new.preload_post

      comments.first.post.should eq(post)
    end
  end

  it "preloads optional belongs_to" do
    with_lazy_load(enabled: false) do
      employee = EmployeeBox.create
      manager = ManagerBox.create

      employees = Employee::BaseQuery.new.preload_manager
      employees.first.manager.should be_nil

      Employee::BaseForm.new(employee).tap do |form|
        form.manager_id.value = manager.id
        form.update!
      end
      employees = Employee::BaseQuery.new.preload_manager
      employees.first.manager.should eq(manager)
    end
  end

  it "preloads uuid belongs_to" do
    item = LineItemBox.create
    price = PriceBox.new.line_item_id(item.id).create

    PriceQuery.new.preload_line_item.first.line_item.should eq item
  end

  it "uses preloaded records if available, even if lazy load is enabled" do
    with_lazy_load(enabled: true) do
      post = PostBox.create
      comment = CommentBox.create &.post_id(post.id)

      posts = Post::BaseQuery.new.preload(
        Comment::BaseQuery.new.id.not.eq(comment.id)
      )

      posts.results.first.comments.should eq([] of Comment)
    end
  end

  it "lazy loads if nothing is preloaded" do
    post = PostBox.create
    comment = CommentBox.create &.post_id(post.id)

    posts = Post::BaseQuery.new

    posts.results.first.comments.should eq([comment])
  end
end
