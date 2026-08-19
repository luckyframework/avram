class CreateDeeplyNestedSaveOperationFixtures::V20240819000000 < Avram::Migrator::Migration::V1
  def migrate
    create table_for(EmailDomainRecord) do
      primary_key id : Int64
      add_timestamps
      add verified : Bool, default: false
      add_belongs_to email_address : EmailAddress, on_delete: :cascade
    end

    create table_for(EmailAlias) do
      primary_key id : Int64
      add_timestamps
      add address : String
      add_belongs_to email_address : EmailAddress, on_delete: :cascade
    end

    create table_for(CommentReaction) do
      primary_key id : Int64
      add_timestamps
      add emoji : String
      add_belongs_to comment : Comment, on_delete: :cascade
    end
  end

  def rollback
    drop table_for(EmailDomainRecord)
    drop table_for(EmailAlias)
    drop table_for(CommentReaction)
  end
end
