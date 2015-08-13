require 'spec_helper'

describe Promiscuous::BlackHole do
  it 'inserts timestamp fields without timezone' do
    PublisherModel.create!(:group => DateTime.iso8601('2001-02-03T04:05:06+07:00'))
    eventually do
      expect(DB[:publisher_models].first[:group]).to eq('2001-02-02 21:05:06 UTC')
    end
  end
end
