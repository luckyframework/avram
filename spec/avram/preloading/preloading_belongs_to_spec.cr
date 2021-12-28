require "../spec_helper"

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
  end
end
