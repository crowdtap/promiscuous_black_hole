module Promiscuous::BlackHole
  class Message
    attr_reader :raw_message

    def initialize(raw_message)
      @raw_message = raw_message
    end

    def attributes
      safe_raw_attributes
        .reject { |_, v| EmbeddedMessage.embedded_value?(v) }
        .merge(
          'id'    => raw_message['id'],
          '_v'    => raw_message['version'],
          '_type' => raw_message['types'].first
        )
    end

    def embedded_messages
      @embedded_messages ||= safe_raw_attributes
        .values
        .select   { |v| EmbeddedMessage.embedded_value?(v) }
        .flat_map { |v| EmbeddedMessage.from_embedded_value(v, self)}
    end

    def table_name
      base_type
        .gsub(/::Base$/, '')
        .gsub(/::/, '_')
        .underscore
        .pluralize
    end

    def base_type
      raw_message['types'].last
    end

    def operation
      raw_message['operation']
    end

    def id
      raw_message['id']
    end

    def to_s
      "<Message:#{ raw_message }>"
    end

    private

    def safe_raw_attributes
      @safe_raw_attributes ||= begin
        attrs = {}

        (raw_message['attributes'] || {}).each do |k, v|
          next if v == [] || v.nil?
          attrs[k] = v.is_a?(Array) ? v.reject(&:nil?) : v
        end

        attrs
      end
    end
  end
end

# XXX Since it inherits from Message, EmbeddedMessage needs to be required
# after the class is declared
require 'promiscuous_black_hole/embedded_message'
