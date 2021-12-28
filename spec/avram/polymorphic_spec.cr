require "../spec_helper"

include LazyLoadHelpers

private class PolymorphicTask < BaseModel
  table do
    column title : String
  end
end

private class PolymorphicTaskList < BaseModel
  table do
    column title : String
  end
end

private class PolymorphicEvent < BaseModel
  table do
    belongs_to task : PolymorphicTask?
    belongs_to task_list : PolymorphicTaskList?
    polymorphic :eventable, associations: [:task, :task_list]
  end
end

private class OptionalPolymorphicEvent < BaseModel
  table :polymorphic_events do
    belongs_to task : PolymorphicTask?
    belongs_to task_list : PolymorphicTaskList?
    polymorphic :optional_eventable, optional: true, associations: [:task, :task_list]
  end
end

class TestPolymorphicSave < PolymorphicEvent::SaveOperation
  before_save do
    task = PolymorphicTask::SaveOperation.create!(title: "Use Lucky")
    task_id.value = task.id
  end
end

describe "polymorphic belongs to" do
  it "allows you to set the association before save" do
    TestPolymorphicSave.create do |op, tp|
      op.valid?.should eq(true)
      tp.should_not be_nil
    end
  end

  it "sets up a method for accessing associated record" do
    task = PolymorphicTask::SaveOperation.create!(title: "Use Lucky")
    event = PolymorphicEvent::SaveOperation.create!(task_id: task.id)
    event.eventable.should eq(task)

    task_list = PolymorphicTaskList::SaveOperation.create!(title: "Use Lucky")
    event = PolymorphicEvent::SaveOperation.create!(task_list_id: task_list.id)
    event.eventable.should eq(task_list)
  end

  it "can require preloading" do
    with_lazy_load(enabled: false) do
      expect_raises Avram::LazyLoadError do
        task = PolymorphicTask::SaveOperation.create!(title: "Use Lucky")
        event = PolymorphicEvent::SaveOperation.create!(task_id: task.id)
        event.eventable # should raise because it was not preloaded
      end
    end
  end

  it "has ! method to allow lazy loading" do
    with_lazy_load(enabled: false) do
      task = PolymorphicTask::SaveOperation.create!(title: "Use Lucky")
      event = PolymorphicEvent::SaveOperation.create!(task_id: task.id)
      event.eventable!.should eq(task)
    end
  end

  it "can preload the polymorphic associations" do
    with_lazy_load(enabled: false) do
      task = PolymorphicTask::SaveOperation.create!(title: "Use Lucky")
      event = PolymorphicEvent::SaveOperation.create!(task_id: task.id)
      event = PolymorphicEvent::BaseQuery.new.preload_eventable.find(event.id)
      event.eventable.should eq(task)

      # Check that it preloads both belongs_to, not just the first
      task_list = PolymorphicTaskList::SaveOperation.create!(title: "Use Lucky")
      event = PolymorphicEvent::SaveOperation.create!(task_list_id: task_list.id)
      event = PolymorphicEvent::BaseQuery.new.preload_eventable.find(event.id)
      event.eventable.should eq(task_list)
    end
  end

  describe "required (default)" do
    it "validates that exactly one polymorphic belongs to is allowed" do
      PolymorphicEvent::SaveOperation.create(task_id: 1, task_list_id: 1) do |operation, _event|
        operation.valid?.should be_false
        operation.task_list_id.errors.should eq(["must be blank"])
      end

      PolymorphicEvent::SaveOperation.create do |operation, _event|
        operation.valid?.should be_false
        operation.task_id.errors.should eq(["at least one 'eventable' must be filled"])
      end
    end

    it "type should not include nil" do
      task = PolymorphicTask::SaveOperation.create!(title: "Use Lucky")
      event = PolymorphicEvent::SaveOperation.create!(task_id: task.id)
      typeof(event.eventable).should eq(PolymorphicTask | PolymorphicTaskList)
      typeof(event.eventable!).should eq(PolymorphicTask | PolymorphicTaskList)
    end
  end

  describe "optional" do
    it "allows not setting a polymorphic association" do
      OptionalPolymorphicEvent::SaveOperation.create do |operation, _event|
        operation.valid?.should be_true
      end
    end

    it "validates that at most one polymorphic belongs to is allowed" do
      OptionalPolymorphicEvent::SaveOperation.create(task_id: 1, task_list_id: 1) do |operation, _event|
        operation.valid?.should be_false
        operation.task_list_id.errors.should eq(["must be blank"])
      end
    end

    it "can return 'nil'" do
      event = OptionalPolymorphicEvent::SaveOperation.create!(task_id: nil, task_list_id: nil)
      typeof(event.optional_eventable).should eq(PolymorphicTask | PolymorphicTaskList | Nil)
      typeof(event.optional_eventable!).should eq(PolymorphicTask | PolymorphicTaskList | Nil)
      event.optional_eventable!.should be_nil
    end
  end
end
