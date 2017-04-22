require "../spec_helper"

describe LuckyRecord::Insert do
  describe "inserting" do
    it "inserts with a hash of String" do
      params = {:first_name => "Paul", :last_name => "Smith"}
      sql = LuckyRecord::Insert.new(table: :users, params: params).to_sql
      sql.should eq ["insert into users(first_name, last_name) values($1, $2)", "Paul", "Smith"]
    end

    it "inserts with a hash of Nil" do
      params = {:first_name => nil}
      sql = LuckyRecord::Insert.new(table: :users, params: params).to_sql
      sql.should eq ["insert into users(first_name) values($1)", nil]
    end

    pending "inserts with a NamedTuple" do
    end
  end
end
