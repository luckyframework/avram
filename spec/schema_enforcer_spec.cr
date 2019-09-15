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
  describe "ensures correct column mappings" do
    it "raises on missing table" do
      expect_raises Exception, "The table 'definitely_a_missing_table' was not found." do
        MissingTable.ensure_correct_column_mappings!
      end
    end

    it "raises on a missing but similarly named table" do
      expect_raises Exception, "The table 'uusers' was not found. Did you mean users?" do
        MissingButSimilarlyNamedTable.ensure_correct_column_mappings!
      end
    end

    it "raises on tables with missing columns" do
      expect_raises Exception, "The table 'users' does not have a 'mickname' column. Did you mean nickname?" do
        ModelWithMissingButSimilarlyNamedColumn.ensure_correct_column_mappings!
      end
    end

    it "raises on nilable column with required columns" do
      expect_raises Exception, "'name' is marked as nilable (name : String?), but the database column does not allow nils." do
        ModelWithOptionalAttributeOnRequiredColumn.ensure_correct_column_mappings!
      end
    end

    it "raises on required columns with nilable columns" do
      expect_raises Exception, "'nickname' is marked as required (nickname : String), but the database column allows nils." do
        ModelWithRequiredAttributeOnOptionalColumn.ensure_correct_column_mappings!
      end
    end
  end
end
