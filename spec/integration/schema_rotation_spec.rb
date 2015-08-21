require 'spec_helper'

describe Promiscuous::BlackHole do
  it 'sets the search path correctly on processing each message' do
    Promiscuous::BlackHole::Config.configure do |cfg|
      cfg.schema_generator = -> { @expected_schema_name }
    end

    [Time.now, Time.now + 1.hour].each do |time_str|
      @expected_schema_name = Time.now.beginning_of_hour.to_i.to_s
      PublisherModel.create!

      eventually do
        DB.transaction_with_applied_schema(@expected_schema_name) do
          expect(DB[:publisher_models].count).to eq 1
        end
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

    sleep 5
    eventually do
      expect(user_written_schemata.sort).to eq((0...test_size).map(&:to_s).sort)

      p 'okokokok'

      test_size.times do |i|
        DB.transaction_with_applied_schema(i) do
          dataset = DB[:publisher_models]
          p dataset.count
        end
      end
      test_size.times do |i|
        DB.transaction_with_applied_schema(i) do
          dataset = DB[:publisher_models]
          expect(dataset.count).to eq(max_writes_per_schema)
        end
      end
    end
  end
end
