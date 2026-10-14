require "../spec_helper"

include LazyLoadHelpers

describe "views" do
  it "works with a primary key" do
    user = UserFactory.create
    AdminFactory.new.name(user.name).create
    admin_user = AdminUser::BaseQuery.find(user.id)

    admin_user.name.should eq user.name
  end

  it "works without a primary key" do
    UserFactory.new.name("P1").nickname("Johnny").create
    UserFactory.new.name("P2").nickname("Johnny").create
    UserFactory.new.name("P3").nickname("Johnny").create
    nickname_info = NicknameInfo::BaseQuery.first

    nickname_info.nickname.should eq "Johnny"
    nickname_info.count.should eq 3
  end

  it "works with SchemaEnforcer" do
    AdminUser.ensure_correct_column_mappings!
    NicknameInfo.ensure_correct_column_mappings!
  end

  describe "materialized views" do
    it "works" do
      UserFactory.create(&.name("Yoozur"))
      AdminFactory.create(&.name("Aadmyn"))
      emp = EmployeeFactory.create(&.name("Hemploie"))
      CustomerFactory.create(&.name("Kustoomur").employee_id(emp.id))
      Name::BaseQuery.new.select_count.should eq(0)
      Name::BaseQuery.refresh_view
      Name::BaseQuery.new.select_count.should eq(4)
    end
  end
end
