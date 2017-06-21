require "./spec_helper"

describe LuckyRecord::Insert do
  describe "inserting" do
    it "inserts with a hash of String" do
      params = {:first_name => "Paul", :last_name => "Smith"}
      insert = LuckyRecord::Insert.new(table: :users, params: params)
      insert.statement.should eq "insert into users(first_name, last_name) values($1, $2) returning *"
      insert.args.should eq ["Paul", "Smith"]
    end

    it "inserts with a hash of Nil" do
      params = {:first_name => nil}
      insert = LuckyRecord::Insert.new(table: :users, params: params)
      insert.statement.should eq "insert into users(first_name) values($1) returning *"
      insert.args.should eq [nil]
    end
  end
end
