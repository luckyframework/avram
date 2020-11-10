class SoftDeletableItem < BaseModel
  include Avram::SoftDelete::Model

  skip_default_columns

  table do
    primary_key id : Int64
    column soft_deleted_at : Time?
    timestamps
  end
end
