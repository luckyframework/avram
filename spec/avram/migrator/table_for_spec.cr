require "../../spec_helper"

describe Avram::TableFor do
  describe ".table_for" do
    it "turns model name into pluralized table name" do
      Avram::TableFor.table_for(User).should eq "users"
    end

    it "removes double colons" do
      Avram::TableFor.table_for(Test::Model).should eq "test_models"
    end

    it "handles constant-case acronym model names" do
      Avram::TableFor.table_for(Test::HTML).should eq "test_htmls"
    end
  end
end
