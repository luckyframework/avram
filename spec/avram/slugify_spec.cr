require "../spec_helper"

describe Avram::Slugify do
  describe ".set" do
    it "does not set anything if slug is already set" do
      op = build_op(title: "Writing Specs")

      slugify(op.slug, "Writing Specs")

      op.slug.value.should eq("writing-specs")
    end

    it "skips blank slug candidates" do
      op = build_op(title: "Software Developer")

      slugify(op.slug, ["", op.title])

      op.slug.value.should eq("software-developer")
    end

    describe "with a single slug candidate" do
      it "it sets slug from a single attribute" do
        op = build_op(title: "Software Developer")

        slugify(op.slug, op.title)

        op.slug.value.should eq("software-developer")
      end

      it "it sets slug from a single string" do
        op = build_op

        slugify(op.slug, "Software Developer")

        op.slug.value.should eq("software-developer")
      end
    end

    describe "with an array of slug candidates" do
      describe "and there is no other record with the same slug" do
        it "sets using a String" do
          op = build_op

          slugify(op.slug, ["Software Developer"])

          op.slug.value.should eq("software-developer")
        end

        it "sets using an attribute" do
          op = build_op(title: "Software Developer")

          slugify(op.slug, [op.title])

          op.slug.value.should eq("software-developer")
        end

        it "sets when using multiple attributes" do
          op = build_op(title: "How Do Magnets Work?", sub_heading: "And Why?")

          slugify(op.slug, [[op.title, op.sub_heading]])

          op.slug.value.should eq("how-do-magnets-work-and-why")
        end
      end

      describe "and the first slug candidate is not unique" do
        it "chooses the first unique one in the array" do
          ArticleFactory.create &.slug("music")
          ArticleFactory.create &.slug("programming")
          op = build_op(title: "Music", sub_heading: "Programming")

          slugify(op.slug, [op.title, "programming", [op.title, op.sub_heading]])

          op.slug.value.should eq("music-programming")
        end
      end

      describe "and all of the slug candidates are used already" do
        it "uses the first present candidate and appends a UUID" do
          ArticleFactory.create &.slug("pizza")
          ArticleFactory.create &.slug("tacos")
          op = build_op(title: "Pizza", sub_heading: "Tacos")

          # First string is empty. Added to make sure it is not used with
          # the UUID.
          slugify(op.slug, ["", op.title, op.sub_heading])

          op.slug.value.to_s.should start_with("pizza-")
          op.slug.value.to_s.split("-", 2).last.size.should eq(UUID.random.to_s.size)
        end
      end

      describe "all slug candidates are blank" do
        it "leaves the slug as nil" do
          op = build_op(title: "")

          # First string is empty. Added to make sure it is not used with
          # the UUID.
          slugify(op.slug, ["", op.title])

          op.slug.value.should be_nil
        end
      end
    end

    it "uses the query to scope uniqueness check" do
      ArticleFactory.create &.slug("the-boss").title("A")

      op = build_op(title: "The Boss")
      slugify(op.slug, op.title, ArticleQuery.new.title("B"))
      op.slug.value.should eq("the-boss")

      op = build_op(title: "The Boss")
      slugify(op.slug, op.title, ArticleQuery.new.title("A"))
      op.slug.value.to_s.should start_with("the-boss-") # Has UUID appended
    end
  end

  describe ".generate" do
    it "skips blank slug candidates" do
      op = build_op(title: "Software Developer")
      slug = Avram::Slugify.generate(op.slug, ["", "Software Developer"], ArticleQuery.new)

      slug.should eq("software-developer")
    end

    describe "with a single slug candidate" do
      it "sets slug from a single attribute" do
        op = build_op(title: "Software Developer")
        slug = Avram::Slugify.generate(op.slug, op.title, ArticleQuery.new)

        slug.should eq("software-developer")
      end

      it "sets slug from a single string" do
        op = build_op(title: "Software Developer")
        slug = Avram::Slugify.generate(op.slug, "Software Developer", ArticleQuery.new)

        slug.should eq("software-developer")
      end
    end

    describe "with an array of slug candidates" do
      it "sets when using multiple attributes" do
        op = build_op(title: "How Do Magnets Work?", sub_heading: "And Why?")

        slug = Avram::Slugify.generate(op.slug, [[op.title, op.sub_heading]], ArticleQuery.new)

        slug.should eq("how-do-magnets-work-and-why")
      end
    end
  end
end

private def slugify(slug, slug_candidates, query = ArticleQuery.new)
  Avram::Slugify.set(slug, slug_candidates, query)
end

private def build_op(**named_args)
  Article::SaveOperation.new(**named_args)
end
