require "./spec_helper"

class KeyHolder < LuckyRecord::Model
  table users do
    has_many sign_in_credentials : SignInCredential, foreign_key: :user_id
  end
end

class KeyHolderQuery < KeyHolder::BaseQuery
end

describe LuckyRecord::Model do
  describe "has_many" do
    it "gets the related records" do
      post = PostBox.save
      comment = CommentBox.new.post_id(post.id).save

      post = Post::BaseQuery.new.find(post.id)

      post.comments.to_a.should eq [comment]
      comment.post.should eq post
    end

    it "gets the related records for nilable association that exists" do
      manager = ManagerBox.save
      employee = EmployeeBox.new.manager_id(manager.id).save

      manager = Manager::BaseQuery.new.find(manager.id)

      manager.employees.to_a.should eq [employee]
      employee.manager.should eq manager
    end

    it "returns nil for nilable association that doesn't exist" do
      employee = EmployeeBox.new.save
      employee.manager.should eq nil
    end

    it "accepts a foreign_key" do
      user = UserBox.save
      cred_1 = SignInCredentialBox.new.user_id(user.id).save
      cred_2 = SignInCredentialBox.new.user_id(user.id).save

      key_holder = KeyHolderQuery.new.first

      key_holder.sign_in_credentials.should eq [cred_1, cred_2]
    end
  end

  describe "has_one" do
    context "missing association" do
      it "raises if association is not nilable" do
        credentialed = AdminBox.save
        expect_raises Exception, "Could not find first record in sign_in_credentials" do
          credentialed.sign_in_credential
        end
      end

      it "returns nil if association is nilable" do
        possibly_credentialed = UserBox.save
        possibly_credentialed.sign_in_credential.should be_nil
      end
    end

    context "existing association" do
      it "returns associated model" do
        user = UserBox.save
        credentials = SignInCredentialBox.new.user_id(user.id).save
        user.sign_in_credential.should eq credentials
      end
    end
  end
end
