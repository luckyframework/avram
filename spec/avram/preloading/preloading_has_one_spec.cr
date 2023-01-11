require "../../spec_helper"

include LazyLoadHelpers

class SignInCredential::BaseQuery
  include QuerySpy
end

describe "Preloading has_one associations" do
  it "works" do
    with_lazy_load(enabled: false) do
      admin = AdminFactory.create
      sign_in_credential = SignInCredentialFactory.create &.user_id(admin.id)

      admin = Admin::BaseQuery.new.preload_sign_in_credential

      admin.first.sign_in_credential.should eq sign_in_credential
    end
  end

  it "works with custom query and nested preload" do
    with_lazy_load(enabled: false) do
      SignInCredential::BaseQuery.times_called = 0
      user = UserFactory.create
      SignInCredentialFactory.create &.user_id(user.id)

      user = User::BaseQuery.new.preload_sign_in_credential(
        SignInCredential::BaseQuery.new.preload_user
      ).first

      user.sign_in_credential.as(SignInCredential).user.should eq user
      SignInCredential::BaseQuery.times_called.should eq 1
    end
  end

  it "works with optional association" do
    with_lazy_load(enabled: false) do
      UserFactory.create
      user = User::BaseQuery.new.preload_sign_in_credential.first
      user.sign_in_credential.should be_nil

      sign_in_credential = SignInCredentialFactory.new.user_id(user.id).create
      user = User::BaseQuery.new.preload_sign_in_credential.first
      user.sign_in_credential.should eq sign_in_credential
    end
  end

  it "raises error if accessing association without preloading first" do
    with_lazy_load(enabled: false) do
      admin = AdminFactory.create
      SignInCredentialFactory.create &.user_id(admin.id)

      expect_raises Avram::LazyLoadError do
        admin.sign_in_credential
      end
    end
  end

  it "does not fail when getting results multiple times" do
    admin = AdminFactory.create
    SignInCredentialFactory.create &.user_id(admin.id)

    admin_query = Admin::BaseQuery.new.preload_sign_in_credential

    2.times { admin_query.results }
  end

  it "lazy loads if nothing is preloaded" do
    admin = AdminFactory.create
    sign_in_credential = SignInCredentialFactory.create &.user_id(admin.id)

    admin.sign_in_credential.should eq sign_in_credential
  end

  it "skips running the preload when there's no results in the parent query" do
    SignInCredential::BaseQuery.times_called = 0
    admin = Admin::BaseQuery.new.preload_sign_in_credential
    admin.results

    SignInCredential::BaseQuery.times_called.should eq 0
  end

  it "raises error if association not nilable but no record found" do
    AdminFactory.create

    expect_raises(Avram::MissingRequiredAssociationError) { Admin::BaseQuery.new.preload_sign_in_credential.results }
  end

  context "with existing record" do
    it "works" do
      with_lazy_load(enabled: false) do
        admin = AdminFactory.create
        sign_in_credential = SignInCredentialFactory.create &.user_id(admin.id)

        admin = Admin::BaseQuery.preload_sign_in_credential(admin)

        admin.sign_in_credential.should eq sign_in_credential
      end
    end

    it "works with multiple" do
      with_lazy_load(enabled: false) do
        admin = AdminFactory.create
        sign_in_credential = SignInCredentialFactory.create &.user_id(admin.id)
        admin2 = AdminFactory.create
        sign_in_credential2 = SignInCredentialFactory.create &.user_id(admin2.id)

        admins = Admin::BaseQuery.preload_sign_in_credential([admin, admin2])

        admins[0].sign_in_credential.should eq(sign_in_credential)
        admins[1].sign_in_credential.should eq(sign_in_credential2)
      end
    end

    it "works with custom query" do
      with_lazy_load(enabled: false) do
        user = UserFactory.create
        sign_in_credential = SignInCredentialFactory.create &.user_id(user.id)

        user = UserQuery.preload_sign_in_credential(user, SignInCredential::BaseQuery.new.id.not.eq(sign_in_credential.id))

        user.sign_in_credential.should be_nil
      end
    end

    it "does not modify original record" do
      with_lazy_load(enabled: false) do
        admin = AdminFactory.create
        SignInCredentialFactory.create &.user_id(admin.id)

        Admin::BaseQuery.preload_sign_in_credential(admin)

        expect_raises Avram::LazyLoadError do
          admin.sign_in_credential
        end
      end
    end

    it "does not refetch association from database if already loaded (even if association has changed)" do
      with_lazy_load(enabled: false) do
        admin = AdminFactory.create
        sign_in_credential = SignInCredentialFactory.create &.user_id(admin.id)
        admin = Admin::BaseQuery.preload_sign_in_credential(admin)
        SignInCredential::SaveOperation.update!(sign_in_credential, value: "THIS IS CHANGED")

        admin = Admin::BaseQuery.preload_sign_in_credential(admin)

        admin.sign_in_credential.value.should_not eq("THIS IS CHANGED")
      end
    end

    it "refetches unfetched in multiple" do
      with_lazy_load(enabled: false) do
        admin1 = AdminFactory.create
        sign_in_credential1 = SignInCredentialFactory.create &.user_id(admin1.id)
        admin1 = Admin::BaseQuery.preload_sign_in_credential(admin1)
        SignInCredential::SaveOperation.update!(sign_in_credential1, value: "THIS IS CHANGED")

        admin2 = AdminFactory.create
        sign_in_credential2 = SignInCredentialFactory.create &.user_id(admin2.id)
        SignInCredential::SaveOperation.update!(sign_in_credential2, value: "THIS IS CHANGED")

        admins = Admin::BaseQuery.preload_sign_in_credential([admin1, admin2])

        admins[0].sign_in_credential.value.should_not eq("THIS IS CHANGED")
        admins[1].sign_in_credential.value.should eq("THIS IS CHANGED")
      end
    end

    it "allows forcing refetch if already loaded" do
      with_lazy_load(enabled: false) do
        admin = AdminFactory.create
        sign_in_credential = SignInCredentialFactory.create &.user_id(admin.id)
        admin = Admin::BaseQuery.preload_sign_in_credential(admin)
        SignInCredential::SaveOperation.update!(sign_in_credential, value: "THIS IS CHANGED")

        admin = Admin::BaseQuery.preload_sign_in_credential(admin, force: true)

        admin.sign_in_credential.value.should eq("THIS IS CHANGED")
      end
    end

    it "allows forcing refetch if already loaded with multiple" do
      with_lazy_load(enabled: false) do
        admin1 = AdminFactory.create
        sign_in_credential1 = SignInCredentialFactory.create &.user_id(admin1.id)
        admin1 = Admin::BaseQuery.preload_sign_in_credential(admin1)
        SignInCredential::SaveOperation.update!(sign_in_credential1, value: "THIS IS CHANGED")

        admin2 = AdminFactory.create
        sign_in_credential2 = SignInCredentialFactory.create &.user_id(admin2.id)
        SignInCredential::SaveOperation.update!(sign_in_credential2, value: "THIS IS CHANGED")

        admins = Admin::BaseQuery.preload_sign_in_credential([admin1, admin2], force: true)

        admins[0].sign_in_credential.value.should eq("THIS IS CHANGED")
        admins[1].sign_in_credential.value.should eq("THIS IS CHANGED")
      end
    end
  end
end
