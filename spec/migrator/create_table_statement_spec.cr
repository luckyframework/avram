require "../spec_helper"

describe LuckyRecord::Migrator::CreateTableStatement do
  it "can create tables with no user defined columns" do
    built = LuckyRecord::Migrator::CreateTableStatement.new(:users).build do
    end

    built.statements.size.should eq 1
    built.statements.first.should eq <<-SQL
    CREATE TABLE users (
      id serial PRIMARY KEY,
      created_at timestamptz NOT NULL,
      updated_at timestamptz NOT NULL);
    SQL
  end

  it "can create tables" do
    built = LuckyRecord::Migrator::CreateTableStatement.new(:users).build do
      add name : String
      add age : Int32
      add completed : Bool
      add joined_at : Time
      add amount_paid : Float, precision: 10, scale: 2
      add email : String?
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
      reference uuid NOT NULL);
    SQL
  end

  it "can create tables with uuid primary keys" do
    built = LuckyRecord::Migrator::CreateTableStatement.new(:users, LuckyRecord::Migrator::PrimaryKeyType::UUID).build do
      add name : String
    end

    built.statements.size.should eq 1
    built.statements.first.should eq <<-SQL
    CREATE TABLE users (
      id uuid PRIMARY KEY,
      created_at timestamptz NOT NULL,
      updated_at timestamptz NOT NULL,
      name text NOT NULL);
    SQL
  end

  it "sets default values" do
    built = LuckyRecord::Migrator::CreateTableStatement.new(:users).build do
      add name : String, default: "name"
      add email : String?, default: "optional"
      add age : Int32, default: 1
      add num : Int64, default: 1
      add amount_paid : Float, default: 1.0
      add completed : Bool, default: false
      add joined_at : Time, default: :now
      add future_time : Time, default: Time.new
    end

    built.statements.size.should eq 1
    built.statements.first.should eq <<-SQL
    CREATE TABLE users (
      id serial PRIMARY KEY,
      created_at timestamptz NOT NULL,
      updated_at timestamptz NOT NULL,
      name text NOT NULL DEFAULT 'name',
      email text DEFAULT 'optional',
      age int NOT NULL DEFAULT 1,
      num bigint NOT NULL DEFAULT 1,
      amount_paid decimal NOT NULL DEFAULT 1.0,
      completed boolean NOT NULL DEFAULT false,
      joined_at timestamptz NOT NULL DEFAULT NOW(),
      future_time timestamptz NOT NULL DEFAULT '#{Time.new.to_utc}');
    SQL
  end

  describe "indices" do
    it "can create tables with indices" do
      built = LuckyRecord::Migrator::CreateTableStatement.new(:users).build do
        add name : String, index: true
        add age : Int32, unique: true
        add email : String

        add_index :email, unique: true
      end

      built.statements.size.should eq 4
      built.statements.first.should eq <<-SQL
      CREATE TABLE users (
        id serial PRIMARY KEY,
        created_at timestamptz NOT NULL,
        updated_at timestamptz NOT NULL,
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
        LuckyRecord::Migrator::CreateTableStatement.new(:users).build do
          add email : String, index: true, using: :gist
        end
      end
    end

    it "raises error when index already exists" do
      expect_raises Exception, "index on users.email already exists" do
        LuckyRecord::Migrator::CreateTableStatement.new(:users).build do
          add email : String, index: true
          add_index :email, unique: true
        end
      end
    end
  end

  describe "associations" do
    it "can create associations" do
      built = LuckyRecord::Migrator::CreateTableStatement.new(:comments).build do
        add_belongs_to user : User, on_delete: :cascade
        add_belongs_to post : Post?, on_delete: :restrict
        add_belongs_to category_label : CategoryLabel, on_delete: :nullify, references: :custom_table
        add_belongs_to employee : User, on_delete: :cascade
        add_belongs_to line_item : LineItem, on_delete: :cascade, foreign_key_type: LuckyRecord::Migrator::PrimaryKeyType::UUID
      end

      built.statements.first.should eq <<-SQL
      CREATE TABLE comments (
        id serial PRIMARY KEY,
        created_at timestamptz NOT NULL,
        updated_at timestamptz NOT NULL,
        user_id int NOT NULL REFERENCES users ON DELETE CASCADE,
        post_id int REFERENCES posts ON DELETE RESTRICT,
        category_label_id int NOT NULL REFERENCES custom_table ON DELETE SET NULL,
        employee_id int NOT NULL REFERENCES users ON DELETE CASCADE,
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
        LuckyRecord::Migrator::CreateTableStatement.new(:users).build do
          add_belongs_to user : User, on_delete: :cascad
        end
      end
    end
  end
end
