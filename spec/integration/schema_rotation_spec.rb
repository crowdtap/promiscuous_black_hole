require 'spec_helper'

describe Promiscuous::BlackHole do
  it 'sets the search path correctly on processing each message' do
    Promiscuous::BlackHole::Config.configure do |cfg|
      cfg.schema_generator = -> { "aa" + Time.now.beginning_of_hour.to_i.to_s }
    end

    ["2015-08-17T11:01:58-04:00", "2015-08-17T12:01:58-04:00"].each do |time_str|
      Timecop.freeze(time_str) do
        PublisherModel.create!
      end

      expected_schema_name = Time.iso8601(time_str).beginning_of_hour.to_i
      table_name = "#{expected_schema_name}__publisher_models"
      eventually do
        expect(DB.raw_connection[table_name].count).to eq 1
      end
    end
  end

  it 'gracefully switches between schemata' do
    test_size = 10
    max_writes_per_schema = 5

    Promiscuous::BlackHole::Config.configure do |cfg|
      schema = writes_to_schema = 0

      cfg.schema_generator = -> do
        if writes_to_schema >= max_writes_per_schema
          writes_to_schema = 1
          schema += 1
        else
          writes_to_schema += 1
        end
        schema
      end
    end

    (test_size * max_writes_per_schema).times do |i|
      field_name = "field_#{i}"

      PublisherModel.instance_eval do
        field field_name
        publish field_name
        create(field_name => 'data')
      end
    end

    eventually do
      expect(user_written_schemata.sort).to eq((0...test_size).map(&:to_s).sort)

      test_size.times do |i|
        dataset = DB[:"#{i}__publisher_models"]
        expect(dataset.count).to eq(max_writes_per_schema)
      end
    end
  end
end
