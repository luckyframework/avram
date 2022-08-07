class Beat < BaseModel
  COLUMN_SQL = "beats.id, beats.created_at, beats.updated_at, beats.hash"

  table do
    column hash : Bytes
  end
end

class BeatQuery < Beat::BaseQuery
end
