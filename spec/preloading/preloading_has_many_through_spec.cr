require "../spec_helper"

include LazyLoadHelpers

class Comment::BaseQuery
  include QuerySpy
end

describe "Preloading has_many through associations" do
  context "through is a has_many association that has a belongs_to relationship to target" do
    it "works" do
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

    it "works with uuid foreign keys" do
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

    it "does not fail when getting results multiple times" do
      PostBox.create

      posts = Post::BaseQuery.new.preload_tags

      2.times { posts.results }
    end
  end

  context "through is a has_many association that has a has_many relationship to target" do
    it "works" do
      with_lazy_load(enabled: false) do
        manager = ManagerBox.create
        employee = EmployeeBox.new.manager_id(manager.id).create
        customer = CustomerBox.new.employee_id(employee.id).create

        customers = Manager::BaseQuery.new.preload_customers.find(manager.id).customers

        customers.size.should eq(1)
        customers.should eq([customer])
      end
    end
  end

  context "through is a belongs_to association that has a belongs_to relationship to target" do
    it "works" do
      with_lazy_load(enabled: false) do
        manager = ManagerBox.create
        employee = EmployeeBox.new.manager_id(manager.id).create
        customer = CustomerBox.new.employee_id(employee.id).create

        managers = Customer::BaseQuery.new.preload_managers.find(customer.id).managers

        managers.size.should eq(1)
        managers.should eq([manager])
      end
    end
  end
end
