require 'spec_helper'

describe Promiscuous::BlackHole do
  it 'creates a correctly named table' do
    expect(DB.table_exists?('publisher_models')).to eq(false)

    PublisherModel.create!

    sleep 0.1

    expect(DB.table_exists?('publisher_models')).to eq(true)
  end

  it 'replaces :: with _ in naming the table' do
    expect(DB.table_exists?('hockey_goals')).to eq(false)

    define_constant :'Hockey::Goal' do
      include Mongoid::Document
      include Promiscuous::Publisher
    end

    Hockey::Goal.create!

    sleep 0.1

    expect(DB.table_exists?('hockey_goals')).to eq(true)
  end

  it 'strips ::Base from namespaced models' do
    expect(DB.table_exists?('publisher_models')).to eq(false)

    define_constant :'PublisherModel::Base' do
      include Mongoid::Document
      include Promiscuous::Publisher
    end

    PublisherModel::Base.create!

    sleep 0.1

    expect(DB.table_exists?('publisher_models')).to eq(true)
  end

  it 'migrates existing json columns' do
    dataset = DB[:publisher_models]
    model = PublisherModel.create

    # Manually create json column and insert data to mimic old storage strategy
    eventually do
      DB.alter_table(:publisher_models) do
        add_column :group, :json
      end
    end
    DB.extension :pg_json
    dataset.update(:id => model.id.to_s, :group => Sequel.pg_json({ 'stored as' => 'json' }))

    # Creating new record should migrate the data type to be correct
    PublisherModel.create(:group => { 'stored as' => 'text' })

    eventually do
      expect(dataset.map { |row| row[:group] }).to eq([
        { 'stored as' => 'json' }.to_json,
        { 'stored as' => 'text' }.to_json
      ])
    end
  end
end
