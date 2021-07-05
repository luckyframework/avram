module PG::Decoders
  struct JsonDecoder
    def decode(io, bytesize, oid)
      if oid == JSONB_OID
        io.read_byte
        bytesize -= 1
      end

      string = String.new(bytesize) do |buffer|
        io.read_fully(Slice.new(buffer, bytesize))
        {bytesize, 0}
      end
      JSON::PullParser.new(string)
    end

    def type
      JSON::PullParser
    end
  end
end
