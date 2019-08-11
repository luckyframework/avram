require "../spec_helper"

describe Avram::Migrator::ChangeTypeStatement do
  it "generates SQL for Int64 (bigint)" do
    statement = Avram::Migrator::ChangeTypeStatement.new(:users, :id, Int64).build
    statement.should eq "ALTER TABLE users ALTER COLUMN id SET DATA TYPE bigint;"
  end

  it "generates SQL for Int32 (integer)" do
    statement = Avram::Migrator::ChangeTypeStatement.new(:users, :id, Int32).build
    statement.should eq "ALTER TABLE users ALTER COLUMN id SET DATA TYPE integer;"
  end
end

describe "actual migration with change_type" do
  it "is able to change type without loosing data" do
    CreateUsersMigration.new.up

    user32 = User32::SaveOperation.new.save!
    ChangeUserPrimaryKey.new.up
    user64 = User64::BaseQuery.find(user32.id)

    user64.id.should eq(user32.id)

    CreateUsersMigration.new.down
  end
end

class CreateUsersMigration < Avram::Migrator::Migration::V1
  def migrate
    create :temp_users do
      primary_key id : Int32
    end
  end

  def rollback
    drop :temp_users
  end
end

class ChangeUserPrimaryKey < Avram::Migrator::Migration::V1
  def migrate
    change_type :temp_users, :id, Int64
  end

  def rollback
    change_type :temp_users, :id, Int32
  end
end

class User32 < BaseModel
  macro default_columns
    primary_key id : Int32
  end

  table :temp_users do
  end
end

class User64 < BaseModel
  macro default_columns
    primary_key id : Int64
  end

  table :temp_users do
  end
end
