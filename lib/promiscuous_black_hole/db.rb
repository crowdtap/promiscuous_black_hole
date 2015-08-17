module Promiscuous::BlackHole
  module DB
    @@connection = nil

    def self.set_schema=(name)
      @@connection.create_schema(name) rescue nil
      @@connection.run("set search_path to #{name}")
    end

    def self.connect(cfg)
      @@connection.try(:disconnect)
      @@connection = Sequel.postgres(cfg.merge(:max_connections => 10, :logger => $>))
      extension :pg_json, :pg_array
    end

    def self.[](table_name)
      @@connection[table_name]
    end

    def self.method_missing(method, *args, &block)
      @@connection.public_send(method, *args, &block)
    end
  end
end
