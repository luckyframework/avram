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
end
