require 'spec_helper'

describe Promiscuous::BlackHole do
  it 'sets the search path correctly on processing each message' do
    Promiscuous::BlackHole::Config.configure do |cfg|
      cfg.schema_generator = -> { Time.now.beginning_of_hour.to_i }
    end

    Timecop.freeze("2015-08-17T11:01:58-04:00") do
      expected_schema_name = Time.now.beginning_of_hour.to_i
      PublisherModel.create!(:group => {:some => :json })

      sleep 3
      expect(DB.fetch('show search_path').to_a).to eql([{:search_path=>"#{expected_schema_name}"}])
    end
    Timecop.freeze("2015-08-17T12:01:58-04:00") do
      expected_schema_name = Time.now.beginning_of_hour.to_i
      PublisherModel.create!(:group => {:some => :json })
      sleep 3
      expect(DB.fetch('show search_path').to_a).to eql([{:search_path=>"#{expected_schema_name}"}])
    end
  end

  it 'gracefully switches between schemata' do
    Promiscuous::BlackHole::Config.configure do |cfg|
      j = -1
      cfg.schema_generator = -> { j += 1 }
    end

    50.times do |i|
      PublisherModel.field "field_#{i}"
      PublisherModel.publish "field_#{i}"
      PublisherModel.create("field_#{i}" => 'data')
      sleep 0.2
    end

    eventually do
      expect(user_written_schemata.sort).to eq((['public'] + (0...50).map(&:to_s)).sort)

      50.times do |i|
        p i
        dataset = DB[:"#{i}__publisher_models"]
        expect(dataset.count).to eq(1)
        p dataset.first
        expect(dataset.first[:"field_#{i}"]).to eq('data')
      end
    end
  end
end
