require "../../../spec_helper"

include ContextHelper

private class SaveLuckyUser < User::SaveOperation
  permit_columns :name, :nickname, :joined_at, :age
  attribute extra : String

  param_key :oooo
end

private class FillLuckyBucket < Bucket::SaveOperation
  permit_columns :bools, :small_numbers, :numbers, :big_numbers, :names
  attribute extras : Array(String)

  param_key :beep
end

describe "OperationParams" do
  it "passes permitted Lucky::Params to the save operation" do
    req = build_request(method: "POST", body: "oooo:name=Dandy&oooo:nickname=mmmm&oooo:joined_at=2020-02-02T20:20:02&oooo:age=49&oooo:extra=cheers")
    params = Lucky::Params.new(req)

    operation = SaveLuckyUser.new(params)
    operation.name.value.should eq("Dandy")
    operation.nickname.value.should eq("mmmm")
    operation.joined_at.value.should eq(Time.utc(2020, 2, 2, 20, 20, 2))
    operation.age.value.should eq(49)
    operation.extra.value.should eq("cheers")
  end

  it "passes permitted array params from Lucky to the save operation" do
    req = build_request(method: "POST", body: "beep:bools[]=true&beep:bools[]=false&beep:small_numbers[]=1&beep:small_numbers[]=2&beep:numbers[]=100&beep:numbers[]=200&beep:big_numbers[]=10000&beep:big_numbers[]=20000&beep:names[]=Rabbit&beep:names[]=Em&beep:extras[]=zap&beep:extra[]=wont_show")
    params = Lucky::Params.new(req)

    operation = FillLuckyBucket.new(params)
    operation.bools.value.should eq([true, false])
    operation.small_numbers.value.should eq([1i16, 2i16])
    operation.numbers.value.should eq([100, 200])
    operation.big_numbers.value.should eq([10000i64, 20000i64])
    operation.names.value.should eq(["Rabbit", "Em"])
    operation.extras.value.should eq(["zap"])
  end
end
