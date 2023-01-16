require "../../spec_helper"

describe Avram::Migrator::AlterTableStatement do
  it "can alter tables with defaults, indices and options" do
    built = Avram::Migrator::AlterTableStatement.new(:users).build do
      add name : String?
      add email : String, fill_existing_with: "noreply@lucky.com"
      add nickname : String, fill_existing_with: :nothing
      add age : Int32, default: 1, unique: true
      add num : Int64, default: 1, index: true
      add amount_paid : Float64, default: 1.0, precision: 10, scale: 5
      add completed : Bool, default: false
      add meta : JSON::Any, default: JSON::Any.new({"default" => JSON::Any.new("value")})
      add joined_at : Time, default: :now
      add updated_at : Time, fill_existing_with: :now
      add future_time : Time, default: Time.local
      add new_id : UUID, default: UUID.new("46d9b2f0-0718-4d4c-a5a1-5af81d5b11e0")
      add numbers : Array(Int32), fill_existing_with: [1]
      rename :old_name, :new_name
      rename_belongs_to :owner, :boss
      remove :old_column
      remove_belongs_to :employee
    end

    built.statements.size.should eq 11

    built.statements[0].should eq "ALTER TABLE users RENAME COLUMN old_name TO new_name;"
    built.statements[1].should eq "ALTER TABLE users RENAME COLUMN owner_id TO boss_id;"

    built.statements[2].should eq <<-SQL
    ALTER TABLE users
      ADD name text,
      ADD email text,
      ADD nickname text NOT NULL,
      ADD age int4 NOT NULL DEFAULT '1',
      ADD num bigint NOT NULL DEFAULT '1',
      ADD amount_paid decimal(10,5) NOT NULL DEFAULT '1.0',
      ADD completed boolean NOT NULL DEFAULT 'false',
      ADD meta jsonb NOT NULL DEFAULT '{"default":"value"}',
      ADD joined_at timestamptz NOT NULL DEFAULT NOW(),
      ADD updated_at timestamptz,
      ADD future_time timestamptz NOT NULL DEFAULT '#{Time.local.to_utc}',
      ADD new_id uuid NOT NULL DEFAULT '46d9b2f0-0718-4d4c-a5a1-5af81d5b11e0',
      ADD numbers int4[],
      DROP old_column,
      DROP employee_id;
    SQL

    built.statements[3].should eq "CREATE UNIQUE INDEX users_age_index ON users USING btree (age);"
    built.statements[4].should eq "CREATE INDEX users_num_index ON users USING btree (num);"
    built.statements[5].should eq "UPDATE users SET email = 'noreply@lucky.com';"
    built.statements[6].should eq "ALTER TABLE users ALTER COLUMN email SET NOT NULL;"
    built.statements[7].should eq "UPDATE users SET updated_at = NOW();"
    built.statements[8].should eq "ALTER TABLE users ALTER COLUMN updated_at SET NOT NULL;"
    built.statements[9].should eq "UPDATE users SET numbers = '{1}';"
    built.statements[10].should eq "ALTER TABLE users ALTER COLUMN numbers SET NOT NULL;"
  end

  it "does not build statements if nothing is altered" do
    built = Avram::Migrator::AlterTableStatement.new(:users).build { }
    built.statements.size.should eq 0
  end

  it "can change column types" do
    built = Avram::Migrator::AlterTableStatement.new(:users).build do
      change_type id : Int64
      change_type age : Float64, precision: 1, scale: 2
      change_type name : String, case_sensitive: false
      change_type total_score : Int32?
    end

    built.statements.size.should eq 4
    built.statements[0].should eq "ALTER TABLE users ALTER COLUMN id SET DATA TYPE bigint;"
    built.statements[1].should eq "ALTER TABLE users ALTER COLUMN age SET DATA TYPE decimal(1,2);"
    built.statements[2].should eq "ALTER TABLE users ALTER COLUMN name SET DATA TYPE citext;"
    built.statements[3].should eq "ALTER TABLE users ALTER COLUMN total_score SET DATA TYPE int4;"
  end

  it "can change column defaults" do
    built = Avram::Migrator::AlterTableStatement.new(:test_defaults).build do
      change_default greeting : String, default: "General Kenobi"
      change_default published_at : Time, default: :now
      change_default money : Float64, default: 29.99
    end

    built.statements.size.should eq 3
    built.statements[0].should eq "ALTER TABLE ONLY test_defaults ALTER COLUMN greeting SET DEFAULT 'General Kenobi';"
    built.statements[1].should eq "ALTER TABLE ONLY test_defaults ALTER COLUMN published_at SET DEFAULT NOW();"
    built.statements[2].should eq "ALTER TABLE ONLY test_defaults ALTER COLUMN money SET DEFAULT '29.99';"
  end

  describe "fill_existing_with" do
    it "fills existing with value and sets column to be non-null for non-null types" do
      built = Avram::Migrator::AlterTableStatement.new(:users).build do
        add confirmed_at : Time, fill_existing_with: :now
      end

      built.statements.size.should eq 3
      built.statements[0].should eq "ALTER TABLE users\n  ADD confirmed_at timestamptz;"
      built.statements[1].should eq "UPDATE users SET confirmed_at = NOW();"
      built.statements[2].should eq "ALTER TABLE users ALTER COLUMN confirmed_at SET NOT NULL;"
    end

    it "fills existing with value and leaves column optional for nilable types" do
      built = Avram::Migrator::AlterTableStatement.new(:users).build do
        add confirmed_at : Time?, fill_existing_with: :now
      end

      built.statements.size.should eq 2
      built.statements[0].should eq "ALTER TABLE users\n  ADD confirmed_at timestamptz;"
      built.statements[1].should eq "UPDATE users SET confirmed_at = NOW();"
    end

    it "fills existing with the correct boolean value" do
      built = Avram::Migrator::AlterTableStatement.new(:users).build do
        add admin : Bool, fill_existing_with: false
      end

      built.statements.size.should eq 3
      built.statements[0].should eq "ALTER TABLE users\n  ADD admin boolean;"
      built.statements[1].should eq "UPDATE users SET admin = 'false';"
      built.statements[2].should eq "ALTER TABLE users ALTER COLUMN admin SET NOT NULL;"
    end
  end

  describe "associations" do
    it "can create associations" do
      built = Avram::Migrator::AlterTableStatement.new(:comments).build do
        add_belongs_to user : User, on_delete: :cascade, unique: true
        add_belongs_to post : Post?, on_delete: :restrict, unique: false
        add_belongs_to category_label : CategoryLabel, on_delete: :nullify, references: :custom_table
        add_belongs_to employee : User, on_delete: :cascade
        add_belongs_to line_item : LineItem, on_delete: :cascade, foreign_key_type: UUID, fill_existing_with: "a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11"
        add_belongs_to subscription_item : Subscription::Item, on_delete: :cascade, references: :subscription_items
      end

      built.statements.first.should eq <<-SQL
      ALTER TABLE comments
        ADD user_id bigint NOT NULL REFERENCES users ON DELETE CASCADE,
        ADD post_id bigint REFERENCES posts ON DELETE RESTRICT,
        ADD category_label_id bigint NOT NULL REFERENCES custom_table ON DELETE SET NULL,
        ADD employee_id bigint NOT NULL REFERENCES users ON DELETE CASCADE,
        ADD line_item_id uuid NOT NULL REFERENCES line_items ON DELETE CASCADE,
        ADD subscription_item_id bigint NOT NULL REFERENCES subscription_items ON DELETE CASCADE;
      SQL

      built.statements[1].should eq "CREATE UNIQUE INDEX comments_user_id_index ON comments USING btree (user_id);"
      built.statements[2].should eq "CREATE INDEX comments_post_id_index ON comments USING btree (post_id);"
      built.statements[3].should eq "CREATE INDEX comments_category_label_id_index ON comments USING btree (category_label_id);"
      built.statements[4].should eq "CREATE INDEX comments_employee_id_index ON comments USING btree (employee_id);"
      built.statements[5].should eq "CREATE INDEX comments_line_item_id_index ON comments USING btree (line_item_id);"
      built.statements[6].should eq "CREATE INDEX comments_subscription_item_id_index ON comments USING btree (subscription_item_id);"
      built.statements[7].should eq "UPDATE comments SET line_item_id = 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11';"
    end

    it "raises error when on_delete strategy is invalid or nil" do
      expect_raises Exception, "on_delete: :cascad is not supported. Please use :do_nothing, :cascade, :restrict, or :nullify" do
        Avram::Migrator::AlterTableStatement.new(:users).build do
          add_belongs_to user : User, on_delete: :cascad
        end
      end
    end

    describe "fill_existing_with" do
      it "fills existing with value and sets column to be non-null for non-null types" do
        built = Avram::Migrator::AlterTableStatement.new(:comments).build do
          add_belongs_to line_item : LineItem, on_delete: :cascade, foreign_key_type: UUID, fill_existing_with: "a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11"
        end

        built.statements.size.should eq 4
        built.statements[0].should eq "ALTER TABLE comments\n  ADD line_item_id uuid NOT NULL REFERENCES line_items ON DELETE CASCADE;"
        built.statements[1].should eq "CREATE INDEX comments_line_item_id_index ON comments USING btree (line_item_id);"
        built.statements[2].should eq "UPDATE comments SET line_item_id = 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11';"
        built.statements[3].should eq "ALTER TABLE comments ALTER COLUMN line_item_id SET NOT NULL;"
      end

      it "fills existing with value and leaves column optional for nilable types" do
        built = Avram::Migrator::AlterTableStatement.new(:comments).build do
          add_belongs_to line_item : LineItem?, on_delete: :cascade, foreign_key_type: UUID, fill_existing_with: "a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11"
        end

        built.statements.size.should eq 3
        built.statements[0].should eq "ALTER TABLE comments\n  ADD line_item_id uuid REFERENCES line_items ON DELETE CASCADE;"
        built.statements[1].should eq "CREATE INDEX comments_line_item_id_index ON comments USING btree (line_item_id);"
        built.statements[2].should eq "UPDATE comments SET line_item_id = 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11';"
      end
    end
  end
end
