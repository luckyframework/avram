require "../../spec_helper"

include LazyLoadHelpers

class Comment::BaseQuery
  include QuerySpy
end

describe "Preloading has_many through associations" do
  context "through is a has_many association that has a belongs_to relationship to target" do
    it "works" do
      with_lazy_load(enabled: false) do
        tag = TagFactory.create
        TagFactory.create # unused tag
        post = PostFactory.create
        other_post = PostFactory.create
        TaggingFactory.create &.tag_id(tag.id).post_id(post.id)
        TaggingFactory.create &.tag_id(tag.id).post_id(other_post.id)

        post_tags = Post::BaseQuery.new.preload_tags.results.first.tags

        post_tags.size.should eq(1)
        post_tags.should eq([tag])
      end
    end

    it "works with uuid foreign keys" do
      with_lazy_load(enabled: false) do
        item = LineItemFactory.create
        other_item = LineItemFactory.create
        product = ProductFactory.create
        ProductFactory.create # unused product
        LineItemProductFactory.create &.line_item_id(item.id).product_id(product.id)
        LineItemProductFactory.create &.line_item_id(other_item.id).product_id(product.id)

        item_products = LineItemQuery.new.preload_associated_products.results.first.associated_products

        item_products.size.should eq(1)
        item_products.should eq([product])
      end
    end

    it "does not fail when getting results multiple times" do
      PostFactory.create

      posts = Post::BaseQuery.new.preload_tags

      2.times { posts.results }
    end
  end

  context "through is a has_many association that has a has_many relationship to target" do
    it "works" do
      with_lazy_load(enabled: false) do
        manager = ManagerFactory.create
        employee = EmployeeFactory.new.manager_id(manager.id).create
        customer = CustomerFactory.new.employee_id(employee.id).create

        customers = Manager::BaseQuery.new.preload_customers.find(manager.id).customers

        customers.size.should eq(1)
        customers.should eq([customer])
      end
    end
  end

  context "through is a belongs_to association that has a belongs_to relationship to target" do
    it "works" do
      with_lazy_load(enabled: false) do
        manager = ManagerFactory.create
        employee = EmployeeFactory.new.manager_id(manager.id).create
        customer = CustomerFactory.new.employee_id(employee.id).create

        managers = Customer::BaseQuery.new.preload_managers.find(customer.id).managers

        managers.size.should eq(1)
        managers.should eq([manager])
      end
    end
  end

  context "with existing record" do
    it "works" do
      with_lazy_load(enabled: false) do
        tag = TagFactory.create
        post = PostFactory.create
        TaggingFactory.create &.tag_id(tag.id).post_id(post.id)

        post = Post::BaseQuery.preload_tags(post)

        post.tags.should eq([tag])
      end
    end

    it "works with multiple" do
      with_lazy_load(enabled: false) do
        tag1 = TagFactory.create
        tag2 = TagFactory.create
        post1 = PostFactory.create
        post2 = PostFactory.create
        TaggingFactory.create &.tag_id(tag1.id).post_id(post1.id)
        TaggingFactory.create &.tag_id(tag2.id).post_id(post2.id)

        posts = Post::BaseQuery.preload_tags([post1, post2])

        posts[0].tags.should eq([tag1])
        posts[1].tags.should eq([tag2])
      end
    end

    it "works with custom query" do
      with_lazy_load(enabled: false) do
        manager = ManagerFactory.create
        employee1 = EmployeeFactory.new.manager_id(manager.id).create
        employee2 = EmployeeFactory.new.manager_id(manager.id).create
        customer1 = CustomerFactory.new.employee_id(employee1.id).create
        CustomerFactory.new.employee_id(employee2.id).create
        customer3 = CustomerFactory.new.employee_id(employee1.id).create

        manager = Manager::BaseQuery.preload_customers(manager, Customer::BaseQuery.new.employee_id(employee1.id))

        # the order of the customers seems to be somewhat random
        manager.customers.sort_by(&.id).should eq([customer1, customer3])
      end
    end

    it "does not modify original record" do
      with_lazy_load(enabled: false) do
        tag = TagFactory.create
        original_post = PostFactory.create
        TaggingFactory.create &.tag_id(tag.id).post_id(original_post.id)

        Post::BaseQuery.preload_tags(original_post)

        expect_raises Avram::LazyLoadError do
          original_post.tags
        end
      end
    end

    it "does not refetch association from database if already loaded (even if association has changed)" do
      with_lazy_load(enabled: false) do
        tag = TagFactory.create
        post = PostFactory.create
        TaggingFactory.create &.tag_id(tag.id).post_id(post.id)
        post = Post::BaseQuery.preload_tags(post)
        Tag::SaveOperation.update!(tag, name: "THIS IS CHANGED")

        post = Post::BaseQuery.preload_tags(post)

        post.tags.first.name.should_not eq("THIS IS CHANGED")
      end
    end

    # TODO
    # it "refetches unfetched in multiple" do
    #   with_lazy_load(enabled: false) do
    #     tag1 = TagFactory.create
    #     post1 = PostFactory.create
    #     TaggingFactory.create &.tag_id(tag1.id).post_id(post1.id)
    #     post1 = Post::BaseQuery.preload_tags(post1)
    #     Tag::SaveOperation.update!(tag1, name: "THIS IS CHANGED")

    #     tag2 = TagFactory.create
    #     post2 = PostFactory.create
    #     TaggingFactory.create &.tag_id(tag2.id).post_id(post2.id)
    #     Tag::SaveOperation.update!(tag1, name: "THIS IS CHANGED")

    #     posts = Post::BaseQuery.preload_tags([post1, post2])

    #     posts[0].tags.first.name.should_not eq("THIS IS CHANGED")
    #     posts[1].tags.first.name.should eq("THIS IS CHANGED")
    #   end
    # end

    it "allows forcing refetch if already loaded" do
      with_lazy_load(enabled: false) do
        tag = TagFactory.create
        post = PostFactory.create
        TaggingFactory.create &.tag_id(tag.id).post_id(post.id)
        post = Post::BaseQuery.preload_tags(post)
        Tag::SaveOperation.update!(tag, name: "THIS IS CHANGED")

        post = Post::BaseQuery.preload_tags(post, force: true)

        post.tags.first.name.should eq("THIS IS CHANGED")
      end
    end

    it "allows forcing refetch if already loaded with multiple" do
      with_lazy_load(enabled: false) do
        tag1 = TagFactory.create
        post1 = PostFactory.create
        TaggingFactory.create &.tag_id(tag1.id).post_id(post1.id)
        post1 = Post::BaseQuery.preload_tags(post1)
        Tag::SaveOperation.update!(tag1, name: "THIS IS CHANGED")

        tag2 = TagFactory.create
        post2 = PostFactory.create
        TaggingFactory.create &.tag_id(tag2.id).post_id(post2.id)
        Tag::SaveOperation.update!(tag2, name: "THIS IS CHANGED")

        posts = Post::BaseQuery.preload_tags([post1, post2], force: true)

        posts[0].tags.first.name.should eq("THIS IS CHANGED")
        posts[1].tags.first.name.should eq("THIS IS CHANGED")
      end
    end
  end
end
