require "../../spec_helper"

include LazyLoadHelpers

class Post::BaseQuery
  include QuerySpy
end

describe "Preloading belongs_to associations" do
  it "works" do
    with_lazy_load(enabled: false) do
      Post::BaseQuery.times_called = 0
      post = PostFactory.create
      CommentFactory.create &.post_id(post.id)

      comments = Comment::BaseQuery.new.preload_post

      comments.first.post.should eq(post)
      Post::BaseQuery.times_called.should eq 1
    end
  end

  it "works with optional association" do
    with_lazy_load(enabled: false) do
      employee = EmployeeFactory.create
      manager = ManagerFactory.create

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

  it "raises error if accessing association without preloading first" do
    with_lazy_load(enabled: false) do
      post = PostFactory.create
      comment = CommentFactory.create &.post_id(post.id)

      comment = Comment::BaseQuery.find(comment.id)

      expect_raises Avram::LazyLoadError do
        comment.post
      end
    end
  end

  it "works with nested preloads" do
    with_lazy_load(enabled: false) do
      post = PostFactory.create
      comment = CommentFactory.create &.post_id(post.id)
      comment2 = CommentFactory.create &.post_id(post.id)

      comment = Comment::BaseQuery.new.preload_post(Post::BaseQuery.new.preload_comments).find(comment.id)

      comment.post.comments.should eq([comment, comment2])
    end
  end

  it "does not fail when getting results multiple times" do
    post = PostFactory.create
    CommentFactory.create &.post_id(post.id)

    query = Comment::BaseQuery.new.preload_post

    2.times { query.results }
  end

  it "works with uuid foreign keys" do
    item = LineItemFactory.create
    PriceFactory.new.line_item_id(item.id).create

    PriceQuery.new.preload_line_item.first.line_item.should eq item
  end

  it "lazy loads if nothing is preloaded" do
    post = PostFactory.create
    comment = CommentFactory.create &.post_id(post.id)

    comment = Comment::BaseQuery.find(comment.id)

    comment.post.should eq(post)
  end

  it "skips running the preload when there's no results in the parent query" do
    Post::BaseQuery.times_called = 0
    comments = Comment::BaseQuery.new.preload_post
    comments.results

    Post::BaseQuery.times_called.should eq 0
  end

  it "raises error if association not nilable but no record found" do
    post = PostFactory.create &.title("Title A")
    CommentFactory.create &.post_id(post.id)

    expect_raises(Avram::MissingRequiredAssociationError) do
      Comment::BaseQuery.new.preload_post(Post::BaseQuery.new.title("Title B")).results
    end
  end

  context "with existing record" do
    it "works" do
      with_lazy_load(enabled: false) do
        post = PostFactory.create
        comment = CommentFactory.create &.post_id(post.id)

        comment = Comment::BaseQuery.preload_post(comment)

        comment.post.should eq(post)
      end
    end

    it "works with multiple" do
      with_lazy_load(enabled: false) do
        post = PostFactory.create
        comment1 = CommentFactory.create &.post_id(post.id)
        comment2 = CommentFactory.create &.post_id(post.id)

        comments = Comment::BaseQuery.preload_post([comment1, comment2])

        comments[0].post.should eq(post)
        comments[1].post.should eq(post)
      end
    end

    it "works with custom query" do
      with_lazy_load(enabled: false) do
        post = PostFactory.create
        comment = CommentFactory.create &.post_id(post.id)
        comment2 = CommentFactory.create &.post_id(post.id)

        comment = Comment::BaseQuery.preload_post(comment, Post::BaseQuery.new.preload_comments)

        comment.post.comments.should eq([comment, comment2])
      end
    end

    it "does not modify original record" do
      with_lazy_load(enabled: false) do
        post = PostFactory.create
        original_comment = CommentFactory.create &.post_id(post.id)

        Comment::BaseQuery.preload_post(original_comment)

        expect_raises Avram::LazyLoadError do
          original_comment.post
        end
      end
    end

    it "does not refetch association from database if already loaded (even if association has changed)" do
      with_lazy_load(enabled: false) do
        post = PostFactory.create
        comment = CommentFactory.create &.post_id(post.id)
        comment = Comment::BaseQuery.preload_post(comment)
        Post::SaveOperation.update!(post, title: "THIS IS CHANGED")

        comment = Comment::BaseQuery.preload_post(comment)

        comment.post.title.should_not eq("THIS IS CHANGED")
      end
    end

    it "refetches unfetched in multiple" do
      with_lazy_load(enabled: false) do
        post = PostFactory.create
        comment1 = CommentFactory.create &.post_id(post.id)
        comment2 = CommentFactory.create &.post_id(post.id)
        comment1 = Comment::BaseQuery.preload_post(comment1)
        Post::SaveOperation.update!(post, title: "THIS IS CHANGED")

        comments = Comment::BaseQuery.preload_post([comment1, comment2])

        comments[0].post.title.should_not eq("THIS IS CHANGED")
        comments[1].post.title.should eq("THIS IS CHANGED")
      end
    end

    it "allows forcing refetch if already loaded" do
      with_lazy_load(enabled: false) do
        post = PostFactory.create
        comment = CommentFactory.create &.post_id(post.id)
        comment = Comment::BaseQuery.preload_post(comment)
        Post::SaveOperation.update!(post, title: "THIS IS CHANGED")

        comment = Comment::BaseQuery.preload_post(comment, force: true)

        comment.post.title.should eq("THIS IS CHANGED")
      end
    end

    it "allows forcing refetch if already loaded with multiple" do
      with_lazy_load(enabled: false) do
        post = PostFactory.create
        comment1 = CommentFactory.create &.post_id(post.id)
        comment2 = CommentFactory.create &.post_id(post.id)
        comment1 = Comment::BaseQuery.preload_post(comment1)
        Post::SaveOperation.update!(post, title: "THIS IS CHANGED")

        comments = Comment::BaseQuery.preload_post([comment1, comment2], force: true)

        comments[0].post.title.should eq("THIS IS CHANGED")
        comments[1].post.title.should eq("THIS IS CHANGED")
      end
    end

    it "works for optional associations" do
      with_lazy_load(enabled: false) do
        business = BusinessFactory.new.create
        email_address = EmailAddressFactory.create &.business_id(business.id)
        email_address = EmailAddressQuery.preload_business(email_address)

        email_address.business.try(&.id).should eq(business.id)
      end
    end
  end
end
