class AddLatitudeAndLongitudeToBusinesses::V20210217224833 < Avram::Migrator::Migration::V1
  def migrate
    execute <<-SQL
      ALTER TABLE businesses
      ADD COLUMN latitude DOUBLE PRECISION,
      ADD COLUMN longitude DOUBLE PRECISION;
    SQL
  end

  def rollback
    alter :businesses do
      remove :latitude
      remove :longitude
    end
  end
end
