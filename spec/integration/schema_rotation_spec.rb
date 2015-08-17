require 'spec_helper'

describe Promiscuous::BlackHole do
  it 'sets the search path to a schema with the timestamp for the current hour' do
    Promiscuous::BlackHole::Config.configure do |cfg|
      cfg.schema_generator = -> { Time.now.beginning_of_hour.to_i }
    end

    Timecop.freeze("2015-08-17T11:01:58-04:00") do
      expected_schema_name = Time.now.beginning_of_hour.to_i
      PublisherModel.create!(:group => {:some => :json })

      sleep 3
      expect(DB.fetch('show search_path').to_a).to eql([{:search_path=>"#{expected_schema_name}"}])
    end
    #check schema
    Timecop.freeze("2015-08-17T12:01:58-04:00") do
      expected_schema_name = Time.now.beginning_of_hour.to_i
      PublisherModel.create!(:group => {:some => :json })
      sleep 3
      expect(DB.fetch('show search_path').to_a).to eql([{:search_path=>"#{expected_schema_name}"}])
    end
    #create
    #check schema
  end
end
