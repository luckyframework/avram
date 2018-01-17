require "./spec_helper"

describe "Preloading" do
  it "can disable lazy loading" do
    with_lazy_load(enabled: false) do
      post = PostBox.save

      posts = Post::BaseQuery.new

      expect_raises LuckyRecord::LazyLoadError do
        posts.first.comments
      end
    end
  end

  it "preloads has_one" do
    with_lazy_load(enabled: false) do
      admin = AdminBox.save
      sign_in_credential = SignInCredentialBox.new.user_id(admin.id).save

      admin = Admin::BaseQuery.new.preload_sign_in_credential

      admin.first.sign_in_credential.should eq sign_in_credential
    end
  end

  it "preloads has_one with custom query and nested preload" do
    with_lazy_load(enabled: false) do
      user = UserBox.save
      sign_in_credential = SignInCredentialBox.new.user_id(user.id).save

      user = User::BaseQuery.new.preload(
        SignInCredential::BaseQuery.new.preload_user
      ).first

      user.sign_in_credential.not_nil!.user.should eq user
    end
  end

  it "preloads optional has_one" do
    with_lazy_load(enabled: false) do
      user = UserBox.save
      user = User::BaseQuery.new.preload_sign_in_credential.first
      user.sign_in_credential.should be_nil

      sign_in_credential = SignInCredentialBox.new.user_id(user.id).save
      user = User::BaseQuery.new.preload_sign_in_credential.first
      user.sign_in_credential.should eq sign_in_credential
    end
  end

  it "preloads has_many" do
    with_lazy_load(enabled: false) do
      post = PostBox.save
      comment = CommentBox.new.post_id(post.id).save

      posts = Post::BaseQuery.new.preload_comments

      posts.results.first.comments.should eq([comment])
    end
  end

  it "preloads has_many with custom query" do
    with_lazy_load(enabled: false) do
      post = PostBox.save
      comment = CommentBox.new.post_id(post.id).save

      posts = Post::BaseQuery.new.preload(
        Comment::BaseQuery.new.id.not(comment.id)
      )

      posts.results.first.comments.should eq([] of Comment)
    end
  end

  it "preloads has_many through" do
    with_lazy_load(enabled: false) do
      tag = TagBox.save
      _unused_tag = TagBox.save
      post = PostBox.save
      other_post = PostBox.save
      TaggingBox.new.tag_id(tag.id).post_id(post.id).save
      TaggingBox.new.tag_id(tag.id).post_id(other_post.id).save

      post_tags = Post::BaseQuery.new.preload_tags.results.first.tags

      post_tags.size.should eq(1)
      post_tags.should eq([tag])
    end
  end

  it "works with nested preloads" do
    with_lazy_load(enabled: false) do
      post = PostBox.save
      comment = CommentBox.new.post_id(post.id).save

      posts = Post::BaseQuery.new.preload(
        Comment::BaseQuery.new.preload_post
      )

      posts.first.comments.first.post.should eq(post)
    end
  end

  it "uses an empty array if there are no associated records" do
    with_lazy_load(enabled: false) do
      post = PostBox.save

      posts = Post::BaseQuery.new.preload_comments

      posts.results.first.comments.should eq([] of Comment)
    end
  end

  it "preloads belongs_to" do
    with_lazy_load(enabled: false) do
      post = PostBox.save
      comment = CommentBox.new.post_id(post.id).save

      comments = Comment::BaseQuery.new.preload_post

      comments.first.post.should eq(post)
    end
  end

  it "preloads optional belongs_to" do
    with_lazy_load(enabled: false) do
      employee = EmployeeBox.save
      manager = ManagerBox.save

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

  it "uses preloaded records if available, even if lazy load is enabled" do
    with_lazy_load(enabled: true) do
      post = PostBox.save
      comment = CommentBox.new.post_id(post.id).save

      posts = Post::BaseQuery.new.preload(
        Comment::BaseQuery.new.id.not(comment.id)
      )

      posts.results.first.comments.should eq([] of Comment)
    end
  end

  it "lazy loads if nothing is preloaded" do
    post = PostBox.save
    comment = CommentBox.new.post_id(post.id).save

    posts = Post::BaseQuery.new

    posts.results.first.comments.should eq([comment])
  end
end

private def with_lazy_load(enabled)
  begin
    LuckyRecord::Repo.configure do
      settings.lazy_load_enabled = enabled
    end

    yield
  ensure
    LuckyRecord::Repo.configure do
      settings.lazy_load_enabled = true
    end
  end
end
