require "../../spec_helper"

private class ModelWithMissingButSimilarlyNamedColumn < BaseModel
  table :users do
    column mickname : String
  end
end

private class ModelWithOptionalAttributeOnRequiredColumn < BaseModel
  table :users do
    column name : String?
  end
end

private class ModelWithRequiredAttributeOnOptionalColumn < BaseModel
  table :users do
    column nickname : String
  end
end

include SchemaEnforcerHelpers

describe Avram::SchemaEnforcer::EnsureMatchingColumns do
  it "raises on tables with missing columns" do
    expect_schema_mismatch "wants to use the column 'mickname' but it does not exist. Did you mean 'nickname'?" do
      ModelWithMissingButSimilarlyNamedColumn.ensure_correct_column_mappings!
    end
  end

  it "raises on nilable column with required columns" do
    expect_schema_mismatch "ModelWithOptionalAttributeOnRequiredColumn has defined 'name' as nilable (String?)" do
      ModelWithOptionalAttributeOnRequiredColumn.ensure_correct_column_mappings!
    end
  end

  it "raises on required columns with nilable columns" do
    expect_schema_mismatch "ModelWithRequiredAttributeOnOptionalColumn has defined 'nickname' as required (String)" do
      ModelWithRequiredAttributeOnOptionalColumn.ensure_correct_column_mappings!
    end
  end

  it "does not check nilable/required if turned off" do
    validation = Avram::SchemaEnforcer::EnsureMatchingColumns.new(ModelWithRequiredAttributeOnOptionalColumn, check_required: false)

    validation.validate!
  end
end
