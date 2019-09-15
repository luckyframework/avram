require "./spec_helper"

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

private class MissingTable < BaseModel
  table :definitely_a_missing_table do
  end
end

private class MissingButSimilarlyNamedTable < BaseModel
  table :uusers do
  end
end

describe Avram::SchemaEnforcer do
  it "automatically adds models to MODELS_TO_ENFORCE" do
    # Just check that it contains some models from this spec
    Avram::SchemaEnforcer::MODELS_TO_ENFORCE.should contain(MissingTable)
  end

  it "does not add abstract models" do
    Avram::SchemaEnforcer::MODELS_TO_ENFORCE.should_not contain(BaseModel)
  end

  it "raises if any of the models have a mismatched schema" do
    expect_raises Avram::SchemaMismatchError do
      Avram::SchemaEnforcer.ensure_correct_column_mappings!
    end
  end

  describe "ensures correct column mappings for a single model" do
    it "raises on missing table" do
      expect_raises Avram::SchemaMismatchError, "wants to use the 'definitely_a_missing_table' table" do
        MissingTable.ensure_correct_column_mappings!
      end
    end

    it "raises on a missing but similarly named table" do
      expect_raises Avram::SchemaMismatchError, "'uusers' table" do
        MissingButSimilarlyNamedTable.ensure_correct_column_mappings!
      end
    end

    it "raises on tables with missing columns" do
      expect_raises Avram::SchemaMismatchError, "wants to use the column 'mickname' but it does not exist. Did you mean 'nickname'?" do
        ModelWithMissingButSimilarlyNamedColumn.ensure_correct_column_mappings!
      end
    end

    it "raises on nilable column with required columns" do
      expect_raises Avram::SchemaMismatchError, "ModelWithOptionalAttributeOnRequiredColumn has defined 'name' as nilable (String?)" do
        ModelWithOptionalAttributeOnRequiredColumn.ensure_correct_column_mappings!
      end
    end

    it "raises on required columns with nilable columns" do
      expect_raises Avram::SchemaMismatchError, "ModelWithRequiredAttributeOnOptionalColumn has defined 'nickname' as required (String)" do
        ModelWithRequiredAttributeOnOptionalColumn.ensure_correct_column_mappings!
      end
    end
  end
end
