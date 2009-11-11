#
#  acts_as_muschable adds support for sharding data over multiple tables by
#  messing with the #table_name method. If you want to shard your data over 
#  multiple databases, use the DataFabric gem, which does the sharding at
#  connection level.
#
module ActiveRecord
  module Acts
    module Muschable
      def self.included(base)
        base.extend(ActsAsMuschableMethod)
      end

      module ActsAsMuschableMethod
        def acts_as_muschable(*args)
          extend ClassMethods

          class_eval do
            #  Sorry for the class << self block, we tried to keep it short.
            class << self; alias_method_chain :table_name, :shard; end
            self.shard_amount = args.last[:shard_amount] || 0
          end
        end
        private :acts_as_muschable
      end

      module ClassMethods
        def initialize_shards
          0.upto(@shard_amount-1) do |i|
            connection.execute("CREATE TABLE #{table_name_for_shard(i)} LIKE #{table_name_without_shard}").free
          end
        end

        @shard_amount = nil
        attr_reader :shard_amount
        def shard_amount=(amount)
          ensure_positive_int('shard_amount', amount)
          @shard_amount = amount
        end

        def activate_shard(shard)
          ensure_positive_int('shard identifier', shard)
          raise ArgumentError, "Can't activate shard, out of range. Adjust #{self.name}.shard_amount=" unless shard<@shard_amount

          ensure_setup
          Thread.current[:shards][self.name.to_sym] = shard.to_s
        end

        def detect_corrupt_shards
          base_schema = table_schema(table_name_without_shard)
          returning Array.new do |corrupt_shards|
            0.upto(shard_amount-1) do |shard|
              shard_schema = table_schema(table_name_for_shard(shard))
              corrupt_shards << shard if shard_schema!=base_schema or base_schema.blank?
            end
          end
        end

        def drop_shards(amount)
          ensure_positive_int('parameter for #drop_shards', amount)
          0.upto(amount-1) do |i|
            connection.execute("DROP TABLE #{table_name_for_shard(i)}").free
          end
        end

        def table_name_with_shard
          ensure_setup
          return table_name_without_shard if @shard_amount==0

          shard = Thread.current[:shards][self.name.to_sym]
          raise ArgumentError, 'No shard has been activated' unless shard

          table_name_for_shard(shard)
        end

        def detect_shard_amount_in_database
          result = connection.execute "SHOW TABLES LIKE '#{table_name_without_shard}%'"
          tables = []
          result.each do |row|
            tables << row[0]
          end
          result.free
          return 0 if tables.size<=1
          tables.sort.last.gsub(table_name_without_shard, '').to_i + 1
        end


        def ensure_setup
          raise ArgumentError, "You have to set #{self.name}.shard_amount" if @shard_amount.nil?
          Thread.current[:shards] ||= Hash.new
        end

        #
        #  This is here because ActiveRecord::Base's table_name method
        #  does something funky. If you call ActiveRecord::Base#table_name
        #  for the first time, it goes through the class hierarchy and
        #  puts together a table name.
        #
        #  Then it redefines the table_name method to instantly return that
        #  name from the first run without going through the class hierarchy
        #  again.
        #
        #  So this method overwrites :table_name_without_shard instead of
        #  the actual #table_name method, so that the name of the shard is
        #  returned.
        #
        def set_table_name(value = nil, &block)
          define_attr_method :table_name_without_shard, value, &block
        end

        def table_name_for_shard(shard)
          "#{table_name_without_shard}#{shard}"
        end

        def ensure_positive_int(name, i)
          raise ArgumentError, "Only positive integers are allowed as #{name}" unless i.is_a?(Integer) and i>=0
        end

        def table_schema(table_name)
          result = connection.execute "SHOW CREATE TABLE #{table_name}"
          schema = ""
          result.each do |row|
            schema << row[1]
          end
          schema.match(/[^\(]+(.*)$/m)[1]
        rescue ActiveRecord::StatementInvalid
          ""
        ensure
          result.free if result
        end
      end
    end
  end
end