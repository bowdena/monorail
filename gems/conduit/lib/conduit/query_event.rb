module Conduit
  QueryEvent = Data.define(
    :application, :source, :resource, :name, :params, :duration,
    :row_count, :record_ids, :error
  ) do
    class << self
      def from_notification(event)
        payload = event.payload

        new(
          application: payload[:application],
          source: payload[:source],
          resource: payload[:resource],
          name: payload[:name],
          params: payload[:params],
          duration: event.duration,
          row_count: payload.fetch(:row_count, 0),
          record_ids: payload.fetch(:record_ids, []),
          error: payload[:error]
        )
      end
    end
  end
end
