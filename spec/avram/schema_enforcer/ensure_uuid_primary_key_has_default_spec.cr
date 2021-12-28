require "../../spec_helper"

private class TableWithoutUUIDPrimaryKey < BaseModel
  table :users do
  end
end

private class TableWithoutDefaultUUID < BaseModel
  table :unused_uuid_table do
  end
end

private class TableWithDefaultUUID < BaseModel
  table :products do
  end
end

include SchemaEnforcerHelpers

describe Avram::SchemaEnforcer::EnsureUUIDPrimaryKeyHasDefault do
  it "does nothing if primary key not uuid" do
    Avram::SchemaEnforcer::EnsureUUIDPrimaryKeyHasDefault.new(TableWithoutUUIDPrimaryKey).validate!
  end

  it "raises when table's uuid primary key does not have default" do
    expect_schema_mismatch "Primary key on the 'unused_uuid_table' table has the type set as uuid but does not have a default value." do
      Avram::SchemaEnforcer::EnsureUUIDPrimaryKeyHasDefault.new(TableWithoutDefaultUUID).validate!
    end
  end

  it "does nothing when table's uuid primary key has default" do
    Avram::SchemaEnforcer::EnsureUUIDPrimaryKeyHasDefault.new(TableWithDefaultUUID).validate!
  end
end
