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

      user = User::BaseQuery.new.preload_sign_in_credential(
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

  it "preloads has_many polymorphic" do
    with_lazy_load(enabled: false) do
      post = PostBox.create
      company = CompanyBox.create

      comment2 = CommentBox.create &.post_id(post.id).body("Comment 1").commentable_type("Company").commentable_id(company.id)
      comment1 = CommentBox.create &.post_id(post.id).body("Comment 2").commentable_type("Company").commentable_id(company.id)

      companies = Company::BaseQuery.new.preload_comments

      comments = companies.results.first.comments
      comments.size.should eq(2)
      comments.should contain(comment1)
      comments.should contain(comment2)
    end
  end

  it "preserves additional criteria when used after adding a preload" do
    with_lazy_load(enabled: false) do
      post = PostBox.create
      another_post = PostBox.create
      comment = CommentBox.create &.post_id(post.id)
      _should_not_be_preloaded = CommentBox.create &.post_id(another_post.id)

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

      posts = Post::BaseQuery.new.preload_comments(
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

  it "preloads belongs_to polymorphic" do
    with_lazy_load(enabled: false) do
      post = PostBox.create
      company = CompanyBox.create
      employee = EmployeeBox.create

      comment1 = CommentBox.create &.post_id(post.id).body("Comment Company 1").commentable_type("Company").commentable_id(company.id)
      comment2 = CommentBox.create &.post_id(post.id).body("Comment Employee 2").commentable_type("Employee").commentable_id(employee.id)
      comment3 = CommentBox.create &.post_id(post.id).body("Comment Company 3").commentable_type("Company").commentable_id(company.id)

      # Commentable 1
      expected_results = {
        comment1.id => {commentable_type: "Company", commentable_id: 1},
        comment2.id => {commentable_type: "Employee", commentable_id: 1},
        comment3.id => {commentable_type: "Company", commentable_id: 1},
      }

      Comment::BaseQuery.new.preload_commentable.results.each do |record|
        commentable = record.commentable

        if commentable.responds_to?(:id)
          commentable.id.should eq(expected_results[record.id][:commentable_id])
        else
          raise Exception.new("Test Failed")
        end
        record.commentable.class.name.should eq(expected_results[record.id][:commentable_type])
      end
    end
  end

  it "preloads optional belongs_to" do
    with_lazy_load(enabled: false) do
      employee = EmployeeBox.create
      manager = ManagerBox.create

      employees = Employee::BaseQuery.new.preload_manager
      employees.first.manager.should be_nil

      Employee::SaveOperation.new(employee).tap do |operation|
        operation.manager_id.value = manager.id
        operation.update!
      end
      employees = Employee::BaseQuery.new.preload_manager
      employees.first.manager.should eq(manager)
    end
  end

  context "getting results for preloads multiple times" do
    it "does not fail for belongs_to" do
      employee = EmployeeBox.create
      employees = Employee::BaseQuery.new.preload_manager

      2.times { employees.results }
    end

    it "does not fail for has_many" do
      post = PostBox.create

      posts = Post::BaseQuery.new.preload_comments

      2.times { posts.results }
    end

    it "does not fail for has_one" do
      admin = AdminBox.create

      admin = Admin::BaseQuery.new.preload_sign_in_credential

      2.times { admin.results }
    end

    it "does not fail for has_many through" do
      post = PostBox.create

      posts = Post::BaseQuery.new.preload_tags

      2.times { posts.results }
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
end
