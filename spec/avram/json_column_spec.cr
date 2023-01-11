require "../spec_helper"

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
    blob.doc.class.should eq Nil
  end

  it "should convert scalars and save forms" do
    form1 = SaveBlob.new
    form1.set_doc_from_param(42)
    form1.set_metadata_from_param(BlobMetadata.from_json("{}"))
    form1.doc.value.should eq JSON::Any.new(42_i64)
    form1.metadata.value.should be_a(BlobMetadata)

    form1.save!
    blob1 = BlobQuery.new.last
    blob1.doc.should eq JSON::Any.new(42_i64)

    form2 = SaveBlob.new
    form2.set_doc_from_param("hey")
    form2.set_metadata_from_param(BlobMetadata.from_json("{}"))
    form2.doc.value.should eq JSON::Any.new("hey")
    form2.save!
    blob2 = BlobQuery.new.last
    blob2.doc.should eq JSON::Any.new("hey")
  end

  it "should convert hashes and arrays and save forms" do
    form1 = SaveBlob.new
    form1.set_doc_from_param(%w[a b c])
    form1.set_metadata_from_param(BlobMetadata.from_json("{}"))
    form1.doc.value.should eq %w[a b c].map { |v| JSON::Any.new(v) }
    form1.save!
    blob1 = BlobQuery.new.last
    blob1.doc.should eq %w[a b c].map { |v| JSON::Any.new(v) }

    form2 = SaveBlob.new
    form2.set_doc_from_param({"foo" => {"bar" => "baz"}})
    form2.set_metadata_from_param(BlobMetadata.from_json("{}"))
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

  it "should convert pre-stringified json objects" do
    form = SaveBlob.new
    form.set_doc_from_param({"foo" => {"bar" => "baz"}}.to_json)
    form.set_metadata_from_param(BlobMetadata.from_json("{}"))
    form.doc.value.should eq JSON::Any.new({
      "foo" => JSON::Any.new({
        "bar" => JSON::Any.new("baz"),
      }),
    })
    form.save!

    blob = BlobQuery.new.last
    blob.doc.should eq JSON::Any.new({
      "foo" => JSON::Any.new({
        "bar" => JSON::Any.new("baz"),
      }),
    })
  end

  describe "serialized" do
    it "saves the serialized value" do
      SaveBlob.create(metadata: BlobMetadata.from_json("{}")) do |operation, blob|
        operation.saved?.should be_true
        blob.should_not be_nil
        blob.as(Blob).metadata.should be_a(BlobMetadata)
        blob.as(Blob).metadata.name.should be_nil
        blob.as(Blob).media.should be_nil
      end
    end

    it "queries serialized columns" do
      one = BlobMetadata.from_json({name: "One", code: 4}.to_json)
      two = BlobMetadata.from_json({name: "Two", code: 9}.to_json)
      BlobFactory.create &.metadata(one)
      BlobFactory.create &.metadata(two)

      BlobQuery.new.metadata(two).select_count.should eq(1)
    end
  end
end
