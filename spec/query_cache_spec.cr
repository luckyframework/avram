require "./spec_helper"

describe Avram::QueryCache do
  it "does not cache on inserts" do
    UserFactory.create &.name("Bob")
    UserFactory.create &.name("Bob")

    UserQuery.new.select_count.should eq(2)
    TestDatabase.cache_vault.empty?.should eq(true)
  end

  it "only runs the query once" do
    UserQuery.new.name("Bob").first?
    UserQuery.new.name("Bob").first?
    UserQuery.new.name("Frank").first?
    UserQuery.new.name("Frank").first?
    UserQuery.new.name("Frank").first?

    # {"Bob sql" => [bob_results], "Frank sql" => [frank_results]}
    TestDatabase.cache_vault.size.should eq(2)
    TestDatabase.cache_counter["miss"].should eq(2)
    TestDatabase.cache_counter["hit"].should eq(3)
  end

  it "doesn't persist cache between specs" do
    TestDatabase.cache_vault.empty?.should eq(true)

    UserQuery.new.name("Bob").first?
    UserQuery.new.name("Bob").first?
    UserQuery.new.name("Bob").first?

    TestDatabase.cache_vault.size.should eq(1)
    TestDatabase.cache_counter["miss"].should eq(1)
    TestDatabase.cache_counter["hit"].should eq(2)
  end
end
