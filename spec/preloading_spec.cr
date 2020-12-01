require "./spec_helper"

include LazyLoadHelpers

class Comment::BaseQuery
  include QuerySpy
end

class SignInCredential::BaseQuery
  include QuerySpy
end

describe "Preloading" do
  it "can disable lazy loading" do
    with_lazy_load(enabled: false) do
      PostBox.create

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
      SignInCredential::BaseQuery.times_called = 0
      user = UserBox.create
      SignInCredentialBox.create &.user_id(user.id)

      user = User::BaseQuery.new.preload_sign_in_credential(
        SignInCredential::BaseQuery.new.preload_user
      ).first

      user.sign_in_credential.not_nil!.user.should eq user
      SignInCredential::BaseQuery.times_called.should eq 1
    end
  end

  it "preloads optional has_one" do
    with_lazy_load(enabled: false) do
      UserBox.create
      user = User::BaseQuery.new.preload_sign_in_credential.first
      user.sign_in_credential.should be_nil

      sign_in_credential = SignInCredentialBox.new.user_id(user.id).create
      user = User::BaseQuery.new.preload_sign_in_credential.first
      user.sign_in_credential.should eq sign_in_credential
    end
  end

  it "preloads has_many" do
    with_lazy_load(enabled: false) do
      Comment::BaseQuery.times_called = 0
      post = PostBox.create
      comment = CommentBox.create &.post_id(post.id)

      posts = Post::BaseQuery.new.preload_comments

      posts.results.first.comments.should eq([comment])
      Comment::BaseQuery.times_called.should eq 1
    end
  end

  it "preserves additional criteria when used after adding a preload" do
    with_lazy_load(enabled: false) do
      post = PostBox.create
      another_post = PostBox.create
      comment = CommentBox.create &.post_id(post.id)

      CommentBox.create &.post_id(another_post.id) # should not be preloaded

      posts = Post::BaseQuery.new.preload_comments.limit(1)

      results = posts.results
      results.size.should eq(1)
      results.first.comments.should eq([comment])
    end
  end

  it "preloads has_many with custom query" do
    with_lazy_load(enabled: false) do
      post = PostBox.create
      comment = CommentBox.create &.post_id(post.id)

      posts = Post::BaseQuery.new.preload_comments(
        Comment::BaseQuery.new.id.not.eq(comment.id)
      )

      posts.results.first.comments.should eq([] of Comment)
    end
  end

  it "preloads has_many through a has_many that points to a belongs_to relationship" do
    with_lazy_load(enabled: false) do
      tag = TagBox.create
      TagBox.create # unused tag
      post = PostBox.create
      other_post = PostBox.create
      TaggingBox.create &.tag_id(tag.id).post_id(post.id)
      TaggingBox.create &.tag_id(tag.id).post_id(other_post.id)

      post_tags = Post::BaseQuery.new.preload_tags.results.first.tags

      post_tags.size.should eq(1)
      post_tags.should eq([tag])
    end
  end

  it "preloads has_many through a has_many that points to a has_many relationship" do
    with_lazy_load(enabled: false) do
      manager = ManagerBox.create
      employee = EmployeeBox.new.manager_id(manager.id).create
      customer = CustomerBox.new.employee_id(employee.id).create

      customers = Manager::BaseQuery.new.preload_customers.find(manager.id).customers

      customers.size.should eq(1)
      customers.should eq([customer])
    end
  end

  it "preloads has_many through a belongs_to that points to a belongs_to relationship" do
    with_lazy_load(enabled: false) do
      manager = ManagerBox.create
      employee = EmployeeBox.new.manager_id(manager.id).create
      customer = CustomerBox.new.employee_id(employee.id).create

      managers = Customer::BaseQuery.new.preload_managers.find(customer.id).managers

      managers.size.should eq(1)
      managers.should eq([manager])
    end
  end

  it "preloads has_many through with uuids" do
    with_lazy_load(enabled: false) do
      item = LineItemBox.create
      other_item = LineItemBox.create
      product = ProductBox.create
      ProductBox.create # unused product
      LineItemProductBox.create &.line_item_id(item.id).product_id(product.id)
      LineItemProductBox.create &.line_item_id(other_item.id).product_id(product.id)

      item_products = LineItemQuery.new.preload_associated_products.results.first.associated_products

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
      CommentBox.create &.post_id(post.id)

      posts = Post::BaseQuery.new.preload_comments(
        Comment::BaseQuery.new.preload_post
      )

      posts.first.comments.first.post.should eq(post)
    end
  end

  it "uses an empty array if there are no associated records" do
    with_lazy_load(enabled: false) do
      PostBox.create

      posts = Post::BaseQuery.new.preload_comments

      posts.results.first.comments.should eq([] of Comment)
    end
  end

  context "getting results for preloads multiple times" do
    it "does not fail for has_many" do
      PostBox.create

      posts = Post::BaseQuery.new.preload_comments

      2.times { posts.results }
    end

    it "does not fail for has_many with custom query" do
      post = PostBox.create
      _another_post = PostBox.create
      comment = CommentBox.create &.post_id(post.id)

      posts = Post::BaseQuery.new.preload_comments(
        Comment::BaseQuery.new.id.not.eq(comment.id)
      )

      2.times { posts.results }
    end

    it "does not fail for has_one" do
      AdminBox.create

      admin = Admin::BaseQuery.new.preload_sign_in_credential

      2.times { admin.results }
    end

    it "does not fail for has_many through" do
      PostBox.create

      posts = Post::BaseQuery.new.preload_tags

      2.times { posts.results }
    end
  end

  it "uses preloaded records if available, even if lazy load is enabled" do
    with_lazy_load(enabled: true) do
      post = PostBox.create
      comment = CommentBox.create &.post_id(post.id)

      posts = Post::BaseQuery.new.preload_comments(
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

  describe "when there's no results in the parent query" do
    it "skips running the preload query for has_many" do
      Comment::BaseQuery.times_called = 0
      posts = Post::BaseQuery.new.preload_comments
      posts.results

      Comment::BaseQuery.times_called.should eq 0
    end

    it "skips running the preload for has_one" do
      SignInCredential::BaseQuery.times_called = 0
      admin = Admin::BaseQuery.new.preload_sign_in_credential
      admin.results

      SignInCredential::BaseQuery.times_called.should eq 0
    end
  end
end
