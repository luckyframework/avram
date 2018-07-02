require "./spec_helper"

private class QueryMe < LuckyRecord::Model
  COLUMNS = "users.id, users.created_at, users.updated_at, users.email, users.age"

  table users do
    column email : CustomEmail
    column age : Int32
  end
end

private class ModelWithMissingButSimilarlyNamedColumn < LuckyRecord::Model
  table users do
    column mickname : String
  end
end

private class ModelWithOptionalFieldOnRequiredColumn < LuckyRecord::Model
  table users do
    column name : String?
  end
end

private class ModelWithRequiredFieldOnOptionalColumn < LuckyRecord::Model
  table users do
    column nickname : String
  end
end

private class MissingTable < LuckyRecord::Model
  table definitely_a_missing_table do
  end
end

private class MissingButSimilarlyNamedTable < LuckyRecord::Model
  table uusers do
  end
end

private class EmptyModelCompilesOk < LuckyRecord::Model
  table no_fields do
  end
end

describe LuckyRecord::Model do
  it "sets up initializers based on the fields" do
    now = Time.now

    user = User.new id: 123,
      name: "Name",
      age: 24,
      joined_at: now,
      created_at: now,
      updated_at: now,
      nickname: "nick"

    user.name.should eq "Name"
    user.age.should eq 24
    user.joined_at.should eq now
    user.updated_at.should eq now
    user.created_at.should eq now
    user.nickname.should eq "nick"
  end

  it "can be used for params" do
    now = Time.now

    user = User.new id: 123,
      name: "Name",
      age: 24,
      joined_at: now,
      created_at: now,
      updated_at: now,
      nickname: "nick"

    user.to_param.should eq "123"
  end

  it "sets up getters that parse the values" do
    user = QueryMe.new id: 123,
      created_at: Time.now,
      updated_at: Time.now,
      age: 30,
      email: " Foo@bar.com "

    user.email.should be_a(CustomEmail)
    user.email.to_s.should eq "foo@bar.com"
  end

  it "sets up simple methods for equality" do
    query = QueryMe::BaseQuery.new.email("foo@bar.com").age(30)

    query.to_sql.should eq ["SELECT #{QueryMe::COLUMNS} FROM users WHERE users.email = $1 AND users.age = $2", "foo@bar.com", "30"]
  end

  it "sets up advanced criteria methods" do
    query = QueryMe::BaseQuery.new.email.upper.is("foo@bar.com").age.gt(30)

    query.to_sql.should eq ["SELECT #{QueryMe::COLUMNS} FROM users WHERE UPPER(users.email) = $1 AND users.age > $2", "foo@bar.com", "30"]
  end

  it "parses values" do
    query = QueryMe::BaseQuery.new.email.upper.is(" Foo@bar.com").age.gt(30)

    query.to_sql.should eq ["SELECT #{QueryMe::COLUMNS} FROM users WHERE UPPER(users.email) = $1 AND users.age > $2", "foo@bar.com", "30"]
  end

  it "lets you order by columns" do
    query = QueryMe::BaseQuery.new.age.asc_order.email.desc_order

    query.to_sql.should eq ["SELECT #{QueryMe::COLUMNS} FROM users ORDER BY users.age ASC, users.email DESC"]
  end

  it "can be deleted" do
    UserBox.create
    user = UserQuery.new.first

    user.delete

    User::BaseQuery.all.size.should eq 0
  end

  describe ".column_names" do
    it "returns list of mapped fields" do
      QueryMe.column_names.should eq [:id, :created_at, :updated_at, :email, :age]
    end
  end

  describe ".ensure_correct_field_mappings" do
    it "raises on missing table" do
      missing_table = MissingTable.new(1, Time.new, Time.new)
      expect_raises Exception, "The table 'definitely_a_missing_table' was not found." do
        missing_table.ensure_correct_field_mappings!
      end
    end

    it "raises on a missing but similarly named table" do
      missing_table = MissingButSimilarlyNamedTable.new(1, Time.new, Time.new)
      expect_raises Exception, "The table 'uusers' was not found. Did you mean users?" do
        missing_table.ensure_correct_field_mappings!
      end
    end

    it "raises on fields with missing columns" do
      now = Time.now
      user = ModelWithMissingButSimilarlyNamedColumn.new id: 1,
        created_at: now,
        updated_at: now,
        mickname: "missing"
      expect_raises Exception, "The table 'users' does not have a 'mickname' column. Did you mean nickname?" do
        user.ensure_correct_field_mappings!
      end
    end

    it "raises on nilable fields with required columns" do
      now = Time.now
      user = ModelWithOptionalFieldOnRequiredColumn.new id: 1,
        created_at: now,
        updated_at: now,
        name: "Mikias"
      expect_raises Exception, "'name' is marked as nilable (name : String?), but the database column does not allow nils." do
        user.ensure_correct_field_mappings!
      end
    end

    it "raises on required fields with nilable columns" do
      now = Time.now
      user = ModelWithRequiredFieldOnOptionalColumn.new id: 1,
        created_at: now,
        updated_at: now,
        nickname: "Miki"
      expect_raises Exception, "'nickname' is marked as required (nickname : String), but the database column allows nils." do
        user.ensure_correct_field_mappings!
      end
    end
  end

  describe "models with uuids" do
    it "sets up initializers accepting uuid strings" do
      uuid = UUID.new("a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11")
      LineItem.new(uuid.to_s, Time.now, Time.now, "hello")
    end

    it "can be saved" do
      uuid_regexp = /\w+/
      LineItemBox.create

      item = LineItemQuery.new.first
      item.id.to_s.should match(uuid_regexp)
    end
  end
end
