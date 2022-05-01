require "../spec_helper"

describe Avram::Join do
  describe "builds statements using defaults" do
    it "::INNER" do
      Avram::Join::Inner.new(:users, :posts).to_sql.should eq "INNER JOIN posts ON users.id = posts.user_id"
    end

    it "::LEFT" do
      Avram::Join::Left.new(:users, :posts).to_sql.should eq "LEFT JOIN posts ON users.id = posts.user_id"
    end

    it "::RIGHT" do
      Avram::Join::Right.new(:users, :posts).to_sql.should eq "RIGHT JOIN posts ON users.id = posts.user_id"
    end

    it "::FULL" do
      Avram::Join::Full.new(:users, :posts).to_sql.should eq "FULL JOIN posts ON users.id = posts.user_id"
    end
  end

  it "allows custom to and from columns" do
    Avram::Join::Inner.new(:users, :posts, primary_key: :uid, foreign_key: :author_id)
      .to_sql
      .should eq "INNER JOIN posts ON users.uid = posts.author_id"
  end

  it "allows different boolean comparisons" do
    Avram::Join::Inner.new(:users, :posts, comparison: "<@", foreign_key: :commenter_ids)
      .to_sql
      .should eq "INNER JOIN posts ON users.id <@ posts.commenter_ids"
  end

  it "allows joining using related columns" do
    Avram::Join::Inner.new(:employees, :managers, using: [:company_id, :department_id])
      .to_sql
      .should eq "INNER JOIN managers USING (company_id, department_id)"
  end
end
