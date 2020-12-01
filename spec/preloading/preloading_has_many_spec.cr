require "../spec_helper"

include LazyLoadHelpers

class Comment::BaseQuery
  include QuerySpy
end

describe "Preloading has_many associations" do
  it "works" do
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

  it "works with custom query" do
    with_lazy_load(enabled: false) do
      post = PostBox.create
      comment = CommentBox.create &.post_id(post.id)

      posts = Post::BaseQuery.new.preload_comments(
        Comment::BaseQuery.new.id.not.eq(comment.id)
      )

      posts.results.first.comments.should eq([] of Comment)
    end
  end

  it "works with UUID foreign keys" do
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

  it "raises error if accessing association without preloading first" do
    with_lazy_load(enabled: false) do
      post = PostBox.create

      expect_raises Avram::LazyLoadError do
        post.comments
      end
    end
  end

  it "uses an empty array if there are no associated records" do
    with_lazy_load(enabled: false) do
      PostBox.create

      posts = Post::BaseQuery.new.preload_comments

      posts.results.first.comments.should eq([] of Comment)
    end
  end

  it "does not fail when getting results multiple times" do
    PostBox.create

    posts = Post::BaseQuery.new.preload_comments

    2.times { posts.results }
  end

  it "does not fail when getting results multiple times with custom query" do
    post = PostBox.create
    _another_post = PostBox.create
    comment = CommentBox.create &.post_id(post.id)

    posts = Post::BaseQuery.new.preload_comments(
      Comment::BaseQuery.new.id.not.eq(comment.id)
    )

    2.times { posts.results }
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

  it "skips running the preload query when there's no results in the parent query" do
    Comment::BaseQuery.times_called = 0
    posts = Post::BaseQuery.new.preload_comments
    posts.results

    Comment::BaseQuery.times_called.should eq 0
  end
end
