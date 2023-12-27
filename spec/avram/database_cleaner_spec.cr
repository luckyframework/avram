require "../spec_helper"

describe "DatabaseCleaner" do
  describe "delete strategy" do
    it "deletes all records" do
      10.times { UserFactory.create }
      UserQuery.new.select_count.should eq 10
      TestDatabase.delete
      UserQuery.new.select_count.should eq 0
    end
  end

  describe "#truncate" do
    it "restarts identity", tags: Avram::SpecHelper::TRUNCATE do
      count = 3

      count.times do
        UserFactory.create
        ArticleFactory.create
      end

      UserQuery.new.select_count.should eq(count)
      ArticleQuery.new.select_count.should eq(count)

      TestDatabase.truncate(restart_identity: true)

      UserQuery.new.select_count.should eq(0)
      ArticleQuery.new.select_count.should eq(0)

      UserFactory.create.id.should eq(1)
      ArticleFactory.create.id.should eq(1)
    end

    it "does not restart identity", tags: Avram::SpecHelper::TRUNCATE do
      count = 3

      count.times do
        UserFactory.create
        ArticleFactory.create
      end

      UserQuery.new.select_count.should eq(count)
      ArticleQuery.new.select_count.should eq(count)

      TestDatabase.truncate(restart_identity: false)

      UserQuery.new.select_count.should eq(0)
      ArticleQuery.new.select_count.should eq(0)

      UserFactory.create.id.should eq(count + 1)
      ArticleFactory.create.id.should eq(count + 1)
    end
  end
end
