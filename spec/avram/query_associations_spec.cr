require "../spec_helper"

class LineItemProductQuery < LineItemProduct::BaseQuery
end

class ProductQuery < Product::BaseQuery
end

# Ensure it works with inherited query classes
class CommentQuery < Comment::BaseQuery
  def body_eq(value)
    body.eq(value)
  end
end

class NamedSpaced::Organization < BaseModel
  table do
    has_many locations : Location
    has_one president : Staff
  end
end

class NamedSpaced::Location < BaseModel
  table do
    column name : String
    belongs_to organization : Organization
  end
end

class NamedSpaced::Staff < BaseModel
  table do
    column name : String
    belongs_to organization : Organization
  end
end

describe "Query associations" do
  it "can query associations" do
    post_with_matching_comment = PostFactory.create
    CommentFactory.new
      .body("matching")
      .post_id(post_with_matching_comment.id)
      .create

    post_without_matching_comment = PostFactory.create
    CommentFactory
      .new
      .body("not-matching")
      .post_id(post_without_matching_comment.id)
      .create

    posts = Post::BaseQuery.new
      .where_comments(CommentQuery.new.body_eq("matching"))
    posts.results.should eq([post_with_matching_comment])

    posts = Post::BaseQuery.new
      .where_comments(Comment::BaseQuery.new.body("matching"))
    posts.results.should eq([post_with_matching_comment])
  end

  it "can query associations with inner_join specified" do
    post_with_matching_comment = PostFactory.create
    CommentFactory.new
      .body("matching")
      .post_id(post_with_matching_comment.id)
      .create

    post_without_matching_comment = PostFactory.create
    CommentFactory.new
      .body("not-matching")
      .post_id(post_without_matching_comment.id)
      .create

    posts = Post::BaseQuery.new
      .inner_join_comments
      .where_comments(Comment::BaseQuery.new.body.eq("matching"), auto_inner_join: false)
    posts.to_sql[0].should contain "INNER JOIN"
    posts.results.should eq([post_with_matching_comment])
  end

  it "can query associations with left_join specified" do
    post_with_matching_comment = PostFactory.create
    CommentFactory.new
      .body("matching")
      .post_id(post_with_matching_comment.id)
      .create

    post_without_matching_comment = PostFactory.create
    CommentFactory.new
      .body("not-matching")
      .post_id(post_without_matching_comment.id)
      .create

    posts = Post::BaseQuery.new
      .left_join_comments
      .where_comments(Comment::BaseQuery.new.body.eq("matching"), auto_inner_join: false)
    posts.to_sql[0].should contain "LEFT JOIN"
    posts.results.should eq([post_with_matching_comment])
  end

  it "can query associations with right_join specified" do
    post_with_matching_comment = PostFactory.create
    CommentFactory.new
      .body("matching")
      .post_id(post_with_matching_comment.id)
      .create

    post_without_matching_comment = PostFactory.create
    CommentFactory.new
      .body("not-matching")
      .post_id(post_without_matching_comment.id)
      .create

    posts = Post::BaseQuery.new
      .right_join_comments
      .where_comments(Comment::BaseQuery.new.body.eq("matching"), auto_inner_join: false)
    posts.to_sql[0].should contain "RIGHT JOIN"
    posts.results.should eq([post_with_matching_comment])
  end

  it "can query associations with full_join specified" do
    post_with_matching_comment = PostFactory.create
    CommentFactory.new
      .body("matching")
      .post_id(post_with_matching_comment.id)
      .create

    post_without_matching_comment = PostFactory.create
    CommentFactory.new
      .body("not-matching")
      .post_id(post_without_matching_comment.id)
      .create

    posts = Post::BaseQuery.new
      .full_join_comments
      .where_comments(Comment::BaseQuery.new.body.eq("matching"), auto_inner_join: false)
    posts.to_sql[0].should contain "FULL JOIN"
    posts.results.should eq([post_with_matching_comment])
  end

  it "can query associations on namespaced models" do
    orgs = NamedSpaced::Organization::BaseQuery.new
      .where_locations(NamedSpaced::Location::BaseQuery.new.name("Home"))
    orgs.to_sql[0].should contain "INNER JOIN"

    staff = NamedSpaced::Staff::BaseQuery.new
    staff.to_sql[0].should contain "named_spaced_staffs"
  end

  it "handles potential joins over the table queried" do
    item = LineItemFactory.create
    product = ProductFactory.create
    line_item_product = LineItemProductFactory.create &.line_item_id(item.id).product_id(product.id)

    line_item_query = LineItemQuery.new
      .id(item.id)
      .where_associated_products(ProductQuery.new.id(product.id))
    result = LineItemProductQuery.new
      .where_line_item(line_item_query)
      .find(line_item_product.id)

    result.should eq(line_item_product)
  end

  it "handles duplicate joins" do
    item = LineItemFactory.create
    product = ProductFactory.create
    line_item_product = LineItemProductFactory.create &.line_item_id(item.id).product_id(product.id)

    line_item_query = LineItemQuery.new
      .id(item.id)
      .where_line_items_products(LineItemProductQuery.new.id(line_item_product.id))
    result = ProductQuery.new
      .where_line_items(line_item_query)
      .find(product.id)

    result.should eq(product)
  end

  it "handles aliases" do
    interviewer = UserFactory.create(&.available_for_hire(false).name("Interviewer"))
    interviewee = UserFactory.create(&.available_for_hire(true).name("Interviewee"))
    employed = UserFactory.create(&.available_for_hire(false).name("Employed"))
    InterviewFactory.create(&.interviewee(interviewee).interviewer(interviewer))
    InterviewFactory.create(&.interviewee(employed).interviewer(interviewer))

    InterviewQuery.new
      .join(Avram::Join::Inner.new(:interviews, :users, alias_to: :interviewers, primary_key: :interviewer_id, foreign_key: :id))
      .join(Avram::Join::Inner.new(:interviews, :users, alias_to: :interviewees, primary_key: :interviewee_id, foreign_key: :id))
      .where_interviewer(UserQuery.new("interviewers").available_for_hire(false), auto_inner_join: false)
      .where_interviewee(UserQuery.new("interviewees").available_for_hire(true), auto_inner_join: false)
      .select_count.should eq(1)
  end
end
