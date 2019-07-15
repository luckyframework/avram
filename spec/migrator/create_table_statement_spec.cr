require "../spec_helper"

describe Avram::Migrator::CreateTableStatement do
  it "can create tables with no user defined columns" do
    built = Avram::Migrator::CreateTableStatement.new(:users).build do
    end

    built.statements.size.should eq 1
    built.statements.first.should eq <<-SQL
    CREATE TABLE users (\n);
    SQL
  end

  it "can create tables" do
    built = Avram::Migrator::CreateTableStatement.new(:users).build do
      primary_key id : Int32
      add_timestamps
      add name : String
      add age : Int32
      add completed : Bool
      add joined_at : Time
      add amount_paid : Float64, precision: 10, scale: 2
      add email : String?
      add meta : JSON::Any?
      add reference : UUID
    end

    built.statements.size.should eq 1
    built.statements.first.should eq <<-SQL
    CREATE TABLE users (
      id serial PRIMARY KEY,
      created_at timestamptz NOT NULL,
      updated_at timestamptz NOT NULL,
      name text NOT NULL,
      age int NOT NULL,
      completed boolean NOT NULL,
      joined_at timestamptz NOT NULL,
      amount_paid decimal(10,2) NOT NULL,
      email text,
      meta jsonb,
      reference uuid NOT NULL);
    SQL
  end

  it "can create tables with other primary keys" do
    built = Avram::Migrator::CreateTableStatement.new(:users).build do
      primary_key id : UUID
    end

    built.statements.size.should eq 1
    built.statements.first.should eq <<-SQL
    CREATE TABLE users (
      id uuid PRIMARY KEY);
    SQL

    built = Avram::Migrator::CreateTableStatement.new(:users).build do
      primary_key custom_id_name : Int64
    end

    built.statements.size.should eq 1
    built.statements.first.should eq <<-SQL
    CREATE TABLE users (
      custom_id_name bigserial PRIMARY KEY);
    SQL

    built = Avram::Migrator::CreateTableStatement.new(:users).build do
      primary_key id : Int16
    end

    built.statements.size.should eq 1
    built.statements.first.should eq <<-SQL
    CREATE TABLE users (
      id smallserial PRIMARY KEY);
    SQL
  end

  it "sets default values" do
    built = Avram::Migrator::CreateTableStatement.new(:users).build do
      add name : String, default: "name"
      add email : String?, default: "optional"
      add age : Int32, default: 1
      add num : Int64, default: 1
      add amount_paid : Float64, default: 1.0
      add completed : Bool, default: false
      add meta : JSON::Any, default: JSON::Any.new(Hash(String, JSON::Any).new)
      add joined_at : Time, default: :now
      add future_time : Time, default: Time.local
      add friend_count : Int16, default: 1
      add friends : Array(String), default: ["Paul"]
    end

    built.statements.size.should eq 1
    built.statements.first.should eq <<-SQL
    CREATE TABLE users (
      name text NOT NULL DEFAULT 'name',
      email text DEFAULT 'optional',
      age int NOT NULL DEFAULT '1',
      num bigint NOT NULL DEFAULT '1',
      amount_paid decimal NOT NULL DEFAULT '1.0',
      completed boolean NOT NULL DEFAULT 'false',
      meta jsonb NOT NULL DEFAULT '{}',
      joined_at timestamptz NOT NULL DEFAULT NOW(),
      future_time timestamptz NOT NULL DEFAULT '#{Time.local.to_utc}',
      friend_count smallint NOT NULL DEFAULT '1',
      friends text[] NOT NULL DEFAULT '["Paul"]');
    SQL
  end

  describe "indices" do
    it "can create tables with indices" do
      built = Avram::Migrator::CreateTableStatement.new(:users).build do
        add name : String, index: true
        add age : Int32, unique: true
        add email : String

        add_index :email, unique: true
      end

      built.statements.size.should eq 4
      built.statements.first.should eq <<-SQL
      CREATE TABLE users (
        name text NOT NULL,
        age int NOT NULL,
        email text NOT NULL);
      SQL
      built.statements[1].should eq "CREATE INDEX users_name_index ON users USING btree (name);"
      built.statements[2].should eq "CREATE UNIQUE INDEX users_age_index ON users USING btree (age);"
      built.statements[3].should eq "CREATE UNIQUE INDEX users_email_index ON users USING btree (email);"
    end

    it "raises error on columns with non allowed index types" do
      expect_raises Exception, "index type 'gist' not supported" do
        Avram::Migrator::CreateTableStatement.new(:users).build do
          add email : String, index: true, using: :gist
        end
      end
    end

    it "raises error when index already exists" do
      expect_raises Exception, "index on users.email already exists" do
        Avram::Migrator::CreateTableStatement.new(:users).build do
          add email : String, index: true
          add_index :email, unique: true
        end
      end
    end
  end

  describe "associations" do
    it "can create associations" do
      built = Avram::Migrator::CreateTableStatement.new(:comments).build do
        add_belongs_to user : User, on_delete: :cascade
        add_belongs_to post : Post?, on_delete: :restrict
        add_belongs_to category_label : CategoryLabel, on_delete: :nullify, references: :custom_table
        add_belongs_to employee : User, on_delete: :cascade
        add_belongs_to line_item : LineItem, on_delete: :cascade, foreign_key_type: UUID
      end

      built.statements.first.should eq <<-SQL
      CREATE TABLE comments (
        user_id bigint NOT NULL REFERENCES users ON DELETE CASCADE,
        post_id bigint REFERENCES posts ON DELETE RESTRICT,
        category_label_id bigint NOT NULL REFERENCES custom_table ON DELETE SET NULL,
        employee_id bigint NOT NULL REFERENCES users ON DELETE CASCADE,
        line_item_id uuid NOT NULL REFERENCES line_items ON DELETE CASCADE);
      SQL

      built.statements[1].should eq "CREATE INDEX comments_user_id_index ON comments USING btree (user_id);"
      built.statements[2].should eq "CREATE INDEX comments_post_id_index ON comments USING btree (post_id);"
      built.statements[3].should eq "CREATE INDEX comments_category_label_id_index ON comments USING btree (category_label_id);"
      built.statements[4].should eq "CREATE INDEX comments_employee_id_index ON comments USING btree (employee_id);"
      built.statements[5].should eq "CREATE INDEX comments_line_item_id_index ON comments USING btree (line_item_id);"
    end

    it "raises error when on_delete strategy is invalid or nil" do
      expect_raises Exception, "on_delete: :cascad is not supported. Please use :do_nothing, :cascade, :restrict, or :nullify" do
        Avram::Migrator::CreateTableStatement.new(:users).build do
          add_belongs_to user : User, on_delete: :cascad
        end
      end
    end
  end

  describe "polymorphic associations" do
    it "can create associations" do
      built = Avram::Migrator::CreateTableStatement.new(:comments).build do
        add_polymorphic_belongs_to :commentable
        add_polymorphic_belongs_to :optional_commentable, optional: true
        add_polymorphic_belongs_to :commentable_uuid, foreign_key_type: UUID
      end

      built.statements.first.should eq <<-SQL
      CREATE TABLE comments (
        commentable_id bigint NOT NULL,
        commentable_type text NOT NULL,
        optional_commentable_id bigint,
        optional_commentable_type text,
        commentable_uuid_id uuid NOT NULL,
        commentable_uuid_type text NOT NULL);
      SQL

      built.statements[1].should eq "CREATE INDEX comments_commentable_id_commentable_type_index ON comments USING btree (commentable_id, commentable_type);"
      built.statements[2].should eq "CREATE INDEX comments_optional_commentable_id_optional_commentable_type_index ON comments USING btree (optional_commentable_id, optional_commentable_type);"
      built.statements[3].should eq "CREATE INDEX comments_commentable_uuid_id_commentable_uuid_type_index ON comments USING btree (commentable_uuid_id, commentable_uuid_type);"
    end
  end
end
