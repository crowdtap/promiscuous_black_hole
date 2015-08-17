module Promiscuous::BlackHole
  module DB
    mattr_accessor :current_schema, :connection_args

    def self.update_schema
      name = Config.schema_generator.call

      unless self.current_schema == name
        self.current_schema = Schema.apply(name)
      end
    end

    def self.connection
      Thread.current[:connection] ||= Sequel.postgres(self.connection_args)
    end

    def self.connect(cfg)
      self.connection_args = cfg.merge(:max_connections => 10)
    end

    def self.[](table_name)
      self.connection[table_name.to_sym]
    end

    def self.method_missing(method, *args, &block)
      self.connection.public_send(method, *args, &block)
    end
  end

  class Schema
    def initialize(name)
      @name = name
    end

    def ==(other)
      @name == other
    end

    def apply
      DB.create_schema(@name) rescue nil
      DB.run("set search_path to #{@name}")
      EmbeddingsTable.ensure_created
    end

    def self.apply(name)
      new(name).apply
    end
  end

  module EmbeddingsTable
    def self.ensure_created
      DB.create_table?(:embeddings) do
        primary_key [:parent_table, :child_table], :name => :embeddings_pk
        column :parent_table, 'varchar(255)'
        column :child_table, 'varchar(255)'
      end
    end
  end
end
