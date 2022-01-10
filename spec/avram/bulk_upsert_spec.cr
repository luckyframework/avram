require "../spec_helper"

describe Avram::BulkUpsert do
  describe "bulk upserts" do
    # Ideally, compiler can catch this / this should be impossible..
    context "when collections mismatch" do
    end

    context "when mixed new records and updated records" do
      # Insert spec example.
      it "inserts with a hash of String" do
        # params = {:first_name => "Paul", :last_name => "Smith"}
        # insert = Avram::Insert.new(table: :users, params: params)
        # insert.statement.should eq "insert into users(first_name, last_name) values($1, $2) returning *"
        # insert.args.should eq ["Paul", "Smith"]
      end
    end
  end
end
