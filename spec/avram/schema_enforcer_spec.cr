require "../spec_helper"

private class ModelWithPerfectlyNormalColumns < BaseModel
  table :test_defaults do
    column greeting : String = "Hello there!"
  end
end

private class TempTable < BaseModel
  skip_schema_enforcer

  table :temp do
  end
end

describe Avram::SchemaEnforcer do
  it "automatically adds models to ALL_MODELS" do
    # Just check that it contains some models from this spec
    Avram::SchemaEnforcer::ALL_MODELS.should contain(ModelWithPerfectlyNormalColumns)
  end

  it "does not enforce schema if 'skip_schema_enforcer' is enabled" do
    # Should not raise
    TempTable.ensure_correct_column_mappings!
  end

  it "does not raise an error when the columns have defaults" do
    # Should not raise
    ModelWithPerfectlyNormalColumns.ensure_correct_column_mappings!
  end

  it "does not add abstract models" do
    Avram::SchemaEnforcer::ALL_MODELS.should_not contain(BaseModel)
  end

  it "raises if any of the models have a mismatched schema" do
    expect_raises Avram::SchemaMismatchError do
      Avram::SchemaEnforcer.ensure_correct_column_mappings!
    end
  end
end
