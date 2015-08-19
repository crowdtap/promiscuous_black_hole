module Promiscuous::BlackHole
  module DB
    mattr_accessor :raw_connection

    def self.connection
      NamespacedConnection.fetch
    end

    def self.connect
      self.raw_connection = Sequel.postgres(Config.connection_args.merge(:max_connections => 10))
      self.raw_connection.extension :pg_json, :pg_array
    end

    def self.disconnect
      self.raw_connection.try(:disconnect)
    end

    def self.method_missing(meth, *args, &block)
      self.connection.public_send(meth, *args, &block)
    end
  end

  class NamespacedConnection
    attr_accessor :current_schema

    def initialize
      self.current_schema = Schema.apply('public')
    end

    def self.fetch
      return Thread.current[:__pool__] if Thread.current[:__pool__]
      Thread.current[:__pool__] = new
    end

    def [](table_name)
      DB.raw_connection[table_name.to_sym]
    end

    def update_schema(name=Config.schema_generator.call)
      unless current_schema == name
        DB.raw_connection.create_schema(@name) rescue nil
        EmbeddingsTable.ensure_created
        self.current_schema = Schema.apply(name)
      end
    end

    def method_missing(meth, *args, &block)
      DB.raw_connection.public_send(meth, *args.map { |arg| "#{current_schema}__#{arg}".to_sym}, &block)
    end
  end

  class Schema
    def initialize(name)
      @name = name.to_s
    end

    def ==(other)
      @name == other.to_s
    end

    def apply
      DB.raw_connection.create_schema(@name) rescue nil
      ensure_embeddings_table
      self
    end

    def self.apply(name)
      new(name).apply
    end

    def ensure_embeddings_table
      DB.raw_connection.create_table?(:"#{@name}__embeddings") do
        primary_key [:parent_table, :child_table], :name => :embeddings_pk
        column :parent_table, 'varchar(255)'
        column :child_table, 'varchar(255)'
      end
    end

    def to_s
      @name
    end
  end
end
