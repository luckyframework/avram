module DB
  class Pool(T)
    def total : Array(T)
      @total
    end

    private def build_resource : T
      resource = @factory.call
      @total << resource
      @idle << resource
      if resource.is_a?(DB::Connection)
        ConnectionStartedEvent.publish(connection: resource)
      end
      resource
    end

    class ConnectionStartedEvent < Pulsar::Event
      def self.clear_subscribers
        subscribers.clear
      end

      getter connection : ::DB::Connection

      def initialize(@connection)
      end
    end
  end
end
