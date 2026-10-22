require "../spec_helper"

describe Avram::Join do
  describe "builds statements using defaults" do
    it "::INNER" do
      Avram::Join::Inner.new(:users, :posts).to_sql.should eq %(INNER JOIN posts ON "users"."id" = "posts"."user_id")
    end

    it "::LEFT" do
      Avram::Join::Left.new(:users, :posts).to_sql.should eq %(LEFT JOIN posts ON "users"."id" = "posts"."user_id")
    end

    it "::RIGHT" do
      Avram::Join::Right.new(:users, :posts).to_sql.should eq %(RIGHT JOIN posts ON "users"."id" = "posts"."user_id")
    end

    it "::FULL" do
      Avram::Join::Full.new(:users, :posts).to_sql.should eq %(FULL JOIN posts ON "users"."id" = "posts"."user_id")
    end
  end

  it "allows custom to and from columns" do
    Avram::Join::Inner.new(:users, :posts, primary_key: :uid, foreign_key: :author_id)
      .to_sql
      .should eq %(INNER JOIN posts ON "users"."uid" = "posts"."author_id")
  end

  it "allows different boolean comparisons" do
    Avram::Join::Inner.new(:users, :posts, comparison: "<@", foreign_key: :commenter_ids)
      .to_sql
      .should eq %(INNER JOIN posts ON "users"."id" <@ "posts"."commenter_ids")
  end

  it "allows joining using related columns" do
    Avram::Join::Inner.new(:employees, :managers, using: [:company_id, :department_id])
      .to_sql
      .should eq %(INNER JOIN managers USING ("company_id", "department_id"))
  end

  it "allows aliasing the to table" do
    Avram::Join::Inner.new(from: :purchases, to: :users, alias_to: :sellers, primary_key: :seller_id, foreign_key: :id)
      .to_sql
      .should eq %(INNER JOIN users AS sellers ON "purchases"."seller_id" = "sellers"."id")
  end

  describe "additional ON conditions" do
    {
      {Avram::Join::Inner, "INNER"},
      {Avram::Join::Left, "LEFT"},
      {Avram::Join::Right, "RIGHT"},
      {Avram::Join::Full, "FULL"},
    }.each do |join_type, keyword|
      it "binds conditions and groups OR predicates for #{keyword} JOIN" do
        conditions = Avram::QueryBuilder.new(:posts)
          .where(Avram::Where::Equal.new("posts.title", "Crystal"))
          .or(&.where(Avram::Where::Equal.new("posts.title", "Ruby")))
        join = join_type.new(:users, :posts, on: conditions.wheres)

        join.to_sql.should eq %(#{keyword} JOIN posts ON "users"."id" = "posts"."user_id" AND (posts.title = $1 OR posts.title = $2))
        join.args.should eq ["Crystal", "Ruby"]
      end
    end

    it "supports aliases and rejects additional ON conditions with USING" do
      conditions = Avram::QueryBuilder.new(:sellers).where(Avram::Where::Equal.new("sellers.name", "Mary"))
      join = Avram::Join::Left.new(:purchases, :users, primary_key: :seller_id, foreign_key: :id, alias_to: :sellers, on: conditions.wheres)

      join.to_sql.should eq %(LEFT JOIN users AS sellers ON "purchases"."seller_id" = "sellers"."id" AND (sellers.name = $1))
      expect_raises(Avram::InvalidQueryError, "Cannot combine USING with additional ON conditions") do
        Avram::Join::Left.new(:purchases, :users, using: [:id], on: conditions.wheres)
      end
    end
  end
end
