require "../spec_helper"

include LazyLoadHelpers

class SignInCredential::BaseQuery
  include QuerySpy
end

describe "Preloading has_one associations" do
  it "works" do
    with_lazy_load(enabled: false) do
      admin = AdminBox.create
      sign_in_credential = SignInCredentialBox.create &.user_id(admin.id)

      admin = Admin::BaseQuery.new.preload_sign_in_credential

      admin.first.sign_in_credential.should eq sign_in_credential
    end
  end

  it "works with custom query and nested preload" do
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

  it "works with optional association" do
    with_lazy_load(enabled: false) do
      UserBox.create
      user = User::BaseQuery.new.preload_sign_in_credential.first
      user.sign_in_credential.should be_nil

      sign_in_credential = SignInCredentialBox.new.user_id(user.id).create
      user = User::BaseQuery.new.preload_sign_in_credential.first
      user.sign_in_credential.should eq sign_in_credential
    end
  end

  it "raises error if accessing association without preloading first" do
    with_lazy_load(enabled: false) do
      admin = AdminBox.create
      sign_in_credential = SignInCredentialBox.create &.user_id(admin.id)

      expect_raises Avram::LazyLoadError do
        admin.sign_in_credential
      end
    end
  end

  it "does not fail when getting results multiple times" do
    AdminBox.create

    admin = Admin::BaseQuery.new.preload_sign_in_credential

    2.times { admin.results }
  end

  it "lazy loads if nothing is preloaded" do
    admin = AdminBox.create
    sign_in_credential = SignInCredentialBox.create &.user_id(admin.id)

    admin.sign_in_credential.should eq sign_in_credential
  end

  it "skips running the preload when there's no results in the parent query" do
    SignInCredential::BaseQuery.times_called = 0
    admin = Admin::BaseQuery.new.preload_sign_in_credential
    admin.results

    SignInCredential::BaseQuery.times_called.should eq 0
  end
end
