require "../spec_helper"

describe Avram::Insert do
  describe "inserting" do
    it "inserts with a hash of String" do
      params = {:first_name => "Paul", :last_name => "Smith"}
      insert = Avram::Insert.new(table: :users, params: params)

      insert.statement.should eq %(INSERT INTO users ("first_name", "last_name") \
        VALUES ($1, $2) RETURNING *)

      insert.args.should eq ["Paul", "Smith"]
    end

    it "inserts with a hash of Nil" do
      params = {:first_name => nil}
      insert = Avram::Insert.new(table: :users, params: params)
      insert.statement.should eq %(INSERT INTO users ("first_name") VALUES ($1) RETURNING *)
      insert.args.should eq [nil]
    end
  end

  describe "upserting" do
    it "updates when keys conflict" do
      params = {:first_name => "Paul", :last_name => "Smith"}

      insert = Avram::Insert.new(
        :users,
        params,
        conflict_action: :update,
        conflict_keys: [:first_name, :last_name],
        conflict_params: [:last_name]
      )

      insert.statement.should eq %(INSERT INTO users ("first_name", "last_name") \
        VALUES ($1, $2) ON CONFLICT ("first_name", "last_name") DO UPDATE SET \
        "last_name" = EXCLUDED."last_name" RETURNING *)
    end

    it "does nothing when keys conflict" do
      params = {:first_name => "Paul", :last_name => "Smith"}

      insert = Avram::Insert.new(
        :users,
        params,
        conflict_action: :nothing,
        conflict_keys: [:first_name, :last_name]
      )

      insert.statement.should eq %(INSERT INTO users ("first_name", "last_name") \
        VALUES ($1, $2) ON CONFLICT ("first_name", "last_name") DO NOTHING RETURNING *)
    end
  end
end
