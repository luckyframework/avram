require "../spec_helper"

describe "Models with different default columns" do
  describe "when there are no timestamps and the primary key is not 'id'" do
    it "find and delete work" do
      model = ModelWithDifferentDefaultColumns::SaveOperation.create!(name: "Karen")
      ModelWithDifferentDefaultColumns::BaseQuery.find(model.custom_id).should eq(model)

      model.delete
      ModelWithDifferentDefaultColumns::BaseQuery.new.select_count.should eq(0)
    end

    it "can create and update" do
      model = ModelWithDifferentDefaultColumns::SaveOperation.create!(name: "Just Created")
      model.name.should eq("Just Created")

      updated_model = ModelWithDifferentDefaultColumns::SaveOperation.update!(model, name: "New Name")
      updated_model.name.should eq("New Name")
    end
  end

  describe "when the primary_key is a custom named UUID" do
    it "still generates a UUID value for the primary_key" do
      model = CustomComment::SaveOperation.create!(body: "beep boop")
      model.custom_id.should be_a UUID
    end
  end
end
