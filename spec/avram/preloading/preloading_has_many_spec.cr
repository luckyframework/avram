require "../../spec_helper"

include LazyLoadHelpers

class Comment::BaseQuery
  include QuerySpy
end

describe "Preloading has_many associations" do
  it "works" do
    with_lazy_load(enabled: false) do
      Comment::BaseQuery.times_called = 0
      post = PostFactory.create
      comment = CommentFactory.create &.post_id(post.id)

      posts = Post::BaseQuery.new.preload_comments

      posts.results.first.comments.should eq([comment])
      Comment::BaseQuery.times_called.should eq 1
    end
  end

  it "preserves additional criteria when used after adding a preload" do
    with_lazy_load(enabled: false) do
      post = PostFactory.create
      another_post = PostFactory.create
      comment = CommentFactory.create &.post_id(post.id)

      CommentFactory.create &.post_id(another_post.id) # should not be preloaded

      posts = Post::BaseQuery.new.preload_comments.limit(1)

      results = posts.results
      results.size.should eq(1)
      results.first.comments.should eq([comment])
    end
  end

  it "works with custom query" do
    with_lazy_load(enabled: false) do
      post = PostFactory.create
      comment = CommentFactory.create &.post_id(post.id)

      posts = Post::BaseQuery.new.preload_comments(
        Comment::BaseQuery.new.id.not.eq(comment.id)
      )

      posts.results.first.comments.should eq([] of Comment)
    end
  end

  it "works with UUID foreign keys" do
    with_lazy_load(enabled: false) do
      item = LineItemFactory.create
      scan = ScanFactory.create &.line_item_id(item.id)

      items = LineItem::BaseQuery.new.preload_scans

      items.results.first.scans.should eq([scan])
    end
  end

  it "works with nested preloads" do
    with_lazy_load(enabled: false) do
      post = PostFactory.create
      CommentFactory.create &.post_id(post.id)

      posts = Post::BaseQuery.new.preload_comments(
        Comment::BaseQuery.new.preload_post
      )

      posts.first.comments.first.post.should eq(post)
    end
  end

  it "raises error if accessing association without preloading first" do
    with_lazy_load(enabled: false) do
      post = PostFactory.create

      expect_raises Avram::LazyLoadError do
        post.comments
      end
    end
  end

  it "uses an empty array if there are no associated records" do
    with_lazy_load(enabled: false) do
      PostFactory.create

      posts = Post::BaseQuery.new.preload_comments

      posts.results.first.comments.should eq([] of Comment)
    end
  end

  it "does not fail when getting results multiple times" do
    PostFactory.create

    posts = Post::BaseQuery.new.preload_comments

    2.times { posts.results }
  end

  it "does not fail when getting results multiple times with custom query" do
    post = PostFactory.create
    _another_post = PostFactory.create
    comment = CommentFactory.create &.post_id(post.id)

    posts = Post::BaseQuery.new.preload_comments(
      Comment::BaseQuery.new.id.not.eq(comment.id)
    )

    2.times { posts.results }
  end

  it "uses preloaded records if available, even if lazy load is enabled" do
    with_lazy_load(enabled: true) do
      post = PostFactory.create
      comment = CommentFactory.create &.post_id(post.id)

      posts = Post::BaseQuery.new.preload_comments(
        Comment::BaseQuery.new.id.not.eq(comment.id)
      )

      posts.results.first.comments.should eq([] of Comment)
    end
  end

  it "lazy loads if nothing is preloaded" do
    post = PostFactory.create
    comment = CommentFactory.create &.post_id(post.id)

    posts = Post::BaseQuery.new

    posts.results.first.comments.should eq([comment])
  end

  it "skips running the preload query when there's no results in the parent query" do
    Comment::BaseQuery.times_called = 0
    posts = Post::BaseQuery.new.preload_comments
    posts.results

    Comment::BaseQuery.times_called.should eq 0
  end

  context "with existing record" do
    it "works" do
      with_lazy_load(enabled: false) do
        post = PostFactory.create
        comment = CommentFactory.create &.post_id(post.id)

        post = Post::BaseQuery.preload_comments(post)

        post.comments.should eq([comment])
      end
    end

    it "works with multiple" do
      with_lazy_load(enabled: false) do
        post1 = PostFactory.create
        post2 = PostFactory.create
        comment1 = CommentFactory.create &.post_id(post1.id)
        comment2 = CommentFactory.create &.post_id(post2.id)

        posts = Post::BaseQuery.preload_comments([post1, post2])

        posts[0].comments.should eq([comment1])
        posts[1].comments.should eq([comment2])
      end
    end

    it "works with custom query" do
      with_lazy_load(enabled: false) do
        post = PostFactory.create
        comment1 = CommentFactory.create &.post_id(post.id).body("CUSTOM BODY")
        CommentFactory.create &.post_id(post.id)

        post = Post::BaseQuery.preload_comments(post, Comment::BaseQuery.new.body("CUSTOM BODY"))

        post.comments.should eq([comment1])
      end
    end

    it "does not modify original record" do
      with_lazy_load(enabled: false) do
        original_post = PostFactory.create
        CommentFactory.create &.post_id(original_post.id)

        Post::BaseQuery.preload_comments(original_post)

        expect_raises Avram::LazyLoadError do
          original_post.comments
        end
      end
    end

    it "does not refetch association from database if already loaded (even if association has changed)" do
      with_lazy_load(enabled: false) do
        post = PostFactory.create
        comment = CommentFactory.create &.post_id(post.id)
        post = Post::BaseQuery.preload_comments(post)
        Comment::SaveOperation.update!(comment, body: "THIS IS CHANGED")

        post = Post::BaseQuery.preload_comments(post)

        post.comments.first.body.should_not eq("THIS IS CHANGED")
      end
    end

    it "refetches unfetched in multiple" do
      with_lazy_load(enabled: false) do
        post1 = PostFactory.create
        post2 = PostFactory.create
        comment1 = CommentFactory.create &.post_id(post1.id)
        post1 = Post::BaseQuery.preload_comments(post1)
        Comment::SaveOperation.update!(comment1, body: "THIS IS CHANGED")
        comment2 = CommentFactory.create &.post_id(post2.id)
        Comment::SaveOperation.update!(comment2, body: "THIS IS CHANGED")

        posts = Post::BaseQuery.preload_comments([post1, post2])

        posts[0].comments.first.body.should_not eq("THIS IS CHANGED")
        posts[1].comments.first.body.should eq("THIS IS CHANGED")
      end
    end

    it "allows forcing refetch if already loaded" do
      with_lazy_load(enabled: false) do
        post = PostFactory.create
        comment = CommentFactory.create &.post_id(post.id)
        post = Post::BaseQuery.preload_comments(post)
        Comment::SaveOperation.update!(comment, body: "THIS IS CHANGED")

        post = Post::BaseQuery.preload_comments(post, force: true)

        post.comments.first.body.should eq("THIS IS CHANGED")
      end
    end

    it "allows forcing refetch if already loaded with multiple" do
      with_lazy_load(enabled: false) do
        post1 = PostFactory.create
        post2 = PostFactory.create
        comment1 = CommentFactory.create &.post_id(post1.id)
        post1 = Post::BaseQuery.preload_comments(post1)
        Comment::SaveOperation.update!(comment1, body: "THIS IS CHANGED")
        comment2 = CommentFactory.create &.post_id(post2.id)
        Comment::SaveOperation.update!(comment2, body: "THIS IS CHANGED")

        posts = Post::BaseQuery.preload_comments([post1, post2], force: true)

        posts[0].comments.first.body.should eq("THIS IS CHANGED")
        posts[1].comments.first.body.should eq("THIS IS CHANGED")
      end
    end
  end
end
