require "../../spec_helper"

private class MissingTable < BaseModel
  table :definitely_a_missing_table do
  end
end

private class MissingButSimilarlyNamedTable < BaseModel
  table :uusers do
  end
end

include SchemaEnforcerHelpers

describe Avram::SchemaEnforcer::EnsureExistingTable do
  it "raises on missing table" do
    expect_schema_mismatch "wants to use the 'definitely_a_missing_table' table" do
      MissingTable.ensure_correct_column_mappings!
    end
  end

  it "raises on a missing but similarly named table" do
    expect_schema_mismatch "'uusers' table" do
      MissingButSimilarlyNamedTable.ensure_correct_column_mappings!
    end
  end
end
