require "./spec_helper"

include LazyLoadHelpers

describe "views" do
  it "works with a primary key" do
    user = UserBox.create
    AdminBox.new.name(user.name).create
    admin_user = AdminUser::BaseQuery.find(user.id)

    admin_user.name.should eq user.name
  end

  it "works without a primary key" do
    UserBox.new.nickname("Johnny").create
    UserBox.new.nickname("Johnny").create
    UserBox.new.nickname("Johnny").create
    nickname_info = NicknameInfo::BaseQuery.first

    nickname_info.nickname.should eq "Johnny"
    nickname_info.count.should eq 3
  end

  pending "works with SchemaEnforcer" do
    AdminUser.ensure_correct_column_mappings!
    NicknameInfo.ensure_correct_column_mappings!
  end
end
