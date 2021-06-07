module Avram::Uploadable
  abstract def tempfile : File
  abstract def metadata : HTTP::FormData::FileMetadata
  # Typically, this should return the filename as found in the `metadata`.
  abstract def filename : String
  # This should test if the filename is a blank string.
  abstract def blank? : Bool

  def self.adapter
    Lucky
  end

  module Lucky
    include Avram::Type

    def parse(value : Avram::Uploadable)
      SuccessfulCast(Avram::Uploadable).new(value)
    end

    def parse(values : Array(Avram::Uploadable))
      SuccessfulCast.new(values)
    end

    def parse(value : String?)
      FailedCast.new
    end

    def parse(values : Array(String))
      FailedCast.new
    end
  end
end
