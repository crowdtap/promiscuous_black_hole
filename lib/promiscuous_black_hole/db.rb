module Promiscuous::BlackHole
  module DB
    def self.connection
      @@connection ||= Sequel.postgres(Config.connection_args.merge(:max_connections => 10)).tap do |conn|
        # conn.loggers = [Logger.new(STDOUT)]
        conn.extension :pg_json, :pg_array
      end
    end

    def self.transaction_with_applied_schema
      transaction do
        Schema.applied do
          yield
        end
      end
    end

    def self.[](arg)
      self.connection[arg.to_sym]
    end

    def self.method_missing(meth, *args, &block)
      self.connection.public_send(meth, *args, &block)
    rescue => e
      # puts '*'*88
      # puts e
      # puts e.backtrace
      raise e
    end
  end

  module Schema
    def self.applied(name=Config.schema_generator.call, &block)
      old_search_path = DB.fetch('SHOW search_path').first[:search_path]
      DB.raw_connection.create_schema(name) rescue nil
      ensure_embeddings_table
      DB << "SET search_path TO #{name}"
      block.call
    ensure
      DB << "SET search_path TO #{old_search_path}"
    end

    def self.ensure_embeddings_table
      DB.create_table?(:embeddings) do
        primary_key [:parent_table, :child_table], :name => :embeddings_pk
        column :parent_table, 'varchar(255)'
        column :child_table, 'varchar(255)'
      end
    end
  end
end
