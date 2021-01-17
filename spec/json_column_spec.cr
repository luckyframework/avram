require "./spec_helper.cr"

class BlobQuery < Blob::BaseQuery
end

class SaveBlob < Blob::SaveOperation
  permit_columns :doc
end

describe "JSON Columns" do
  it "should work in factories" do
    BlobFactory.create
    blob = BlobQuery.new.first
    blob.doc.should eq JSON::Any.new({"foo" => JSON::Any.new("bar")})

    blob2 = BlobFactory.new.doc(JSON::Any.new(42_i64)).create
    blob2.doc.should eq JSON::Any.new(42_i64)
  end

  it "should be nullable" do
    blob = BlobFactory.create
    SaveBlob.update!(blob, doc: nil)
    blob = BlobQuery.new.first
    blob.doc.should eq nil
  end

  it "should convert scalars and save forms" do
    form1 = SaveBlob.new
    form1.set_doc_from_param(42)
    form1.doc.value.should eq JSON::Any.new(42_i64)
    form1.save!
    blob1 = BlobQuery.new.last
    blob1.doc.should eq JSON::Any.new(42_i64)

    form2 = SaveBlob.new
    form2.set_doc_from_param("hey")
    form2.doc.value.should eq JSON::Any.new("hey")
    form2.save!
    blob2 = BlobQuery.new.last
    blob2.doc.should eq JSON::Any.new("hey")
  end

  it "should convert hashes and arrays and save forms" do
    form1 = SaveBlob.new
    form1.set_doc_from_param(%w[a b c])
    form1.doc.value.should eq %w[a b c].map { |v| JSON::Any.new(v) }
    form1.save!
    blob1 = BlobQuery.new.last
    blob1.doc.should eq %w[a b c].map { |v| JSON::Any.new(v) }

    form2 = SaveBlob.new
    form2.set_doc_from_param({"foo" => {"bar" => "baz"}})
    form2.doc.value.should eq JSON::Any.new({
      "foo" => JSON::Any.new({
        "bar" => JSON::Any.new("baz"),
      }),
    })
    form2.save!
    blob2 = BlobQuery.new.last
    blob2.doc.should eq JSON::Any.new({
      "foo" => JSON::Any.new({
        "bar" => JSON::Any.new("baz"),
      }),
    })
  end
end
