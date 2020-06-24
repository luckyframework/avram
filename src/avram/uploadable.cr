# Include this module in classes that represent an uploaded file from a form
module Avram::Uploadable
  getter name : String
  getter tempfile : File
  getter metadata : HTTP::FormData::FileMetadata

  macro included
    # :nodoc:
    def initialize(file : Avram::Uploadable)
      @name = file.name
      @tempfile = file.tempfile
      @metadata = file.metadata
    end
  end

  # Returns the path of the File as a String
  #
  # ```
  # uploaded_file_object.path # => String
  # ```
  def path : String
    @tempfile.path
  end

  # Returns the original file name as a String
  #
  # ```
  # uploaded_file_object.filename # => String
  # ```
  def filename : String
    metadata.filename.to_s
  end

  # If no file was selected in the form's file input, this will return `true`
  #
  # ```
  # uploaded_file_object.blank? # => Bool
  # ```
  def blank? : Bool
    filename.blank?
  end

  module Lucky
    include Avram::Type

    def parse(value : Avram::Uploadable)
      SuccessfulCast(Avram::Uploadable).new(value)
    end

    def parse(value : String?)
      FailedCast.new
    end
  end
end
