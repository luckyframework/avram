require "./spec_helper"

include LazyLoadHelpers

describe "Preloading" do
  it "preloads has_many through a has_many that points to a belongs_to relationship" do
    with_lazy_load(enabled: false) do
      tag = TagBox.create
      TagBox.create # unused tag
      post = PostBox.create
      other_post = PostBox.create
      TaggingBox.create &.tag_id(tag.id).post_id(post.id)
      TaggingBox.create &.tag_id(tag.id).post_id(other_post.id)

      post_tags = Post::BaseQuery.new.preload_tags.results.first.tags

      post_tags.size.should eq(1)
      post_tags.should eq([tag])
    end
  end

  it "preloads has_many through a has_many that points to a has_many relationship" do
    with_lazy_load(enabled: false) do
      manager = ManagerBox.create
      employee = EmployeeBox.new.manager_id(manager.id).create
      customer = CustomerBox.new.employee_id(employee.id).create

      customers = Manager::BaseQuery.new.preload_customers.find(manager.id).customers

      customers.size.should eq(1)
      customers.should eq([customer])
    end
  end

  it "preloads has_many through a belongs_to that points to a belongs_to relationship" do
    with_lazy_load(enabled: false) do
      manager = ManagerBox.create
      employee = EmployeeBox.new.manager_id(manager.id).create
      customer = CustomerBox.new.employee_id(employee.id).create

      managers = Customer::BaseQuery.new.preload_managers.find(customer.id).managers

      managers.size.should eq(1)
      managers.should eq([manager])
    end
  end

  it "preloads has_many through with uuids" do
    with_lazy_load(enabled: false) do
      item = LineItemBox.create
      other_item = LineItemBox.create
      product = ProductBox.create
      ProductBox.create # unused product
      LineItemProductBox.create &.line_item_id(item.id).product_id(product.id)
      LineItemProductBox.create &.line_item_id(other_item.id).product_id(product.id)

      item_products = LineItemQuery.new.preload_associated_products.results.first.associated_products

      item_products.size.should eq(1)
      item_products.should eq([product])
    end
  end

  context "getting results for preloads multiple times" do
    it "does not fail for has_many through" do
      PostBox.create

      posts = Post::BaseQuery.new.preload_tags

      2.times { posts.results }
    end
  end
end
