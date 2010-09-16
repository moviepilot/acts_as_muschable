#
#  acts_as_muschable adds support for sharding data over multiple tables by
#  messing with the #table_name method. If you want to shard your data over 
#  multiple databases, use the DataFabric gem, which does the sharding at
#  connection level.
#
module ActiveRecord
  
  # originally table_name and quoted_table_name are cached both in the model 
  # and in the reflection object. disabling the cache in the reflection object
  # doesn't mean the table name is recalculated on every access, it only gets
  # delegated to (the cached) ReflectedModel.table_name every time, meaning
  # one more method call.
  module Reflection
    class AssociationReflection
      def table_name
        klass.table_name
      end
  
      def quoted_table_name
        klass.quoted_table_name
      end
    end
  end
  
  module Acts
    module Muschable
      def self.included(base)
        raise StandardError, "acts_as_muschable is only tested against ActiveRecord -v=2.3.5" if defined?(::Rails) and ::Rails.version>'2.3.5'
        base.extend(ActsAsMuschableLoader)
      end

      module ActsAsMuschableLoader
        def acts_as_muschable(*args)
          raise RuntimeError, "You called acts_as_muschable twice" unless @class_musched.nil?
          @class_musched = true
          extend ClassMethods
          class_eval do
            class << self; alias_method_chain :table_name, :shard; end
            self.shard_amount = args.last[:shard_amount] || 0
          end
        end
        private :acts_as_muschable
      end

      module ClassMethods
        
        def initialize_shards
          0.upto(@shard_amount-1) do |i|
            connection.execute("CREATE TABLE #{table_name_for_shard(i)} LIKE #{table_name_without_shard}")
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
        
        def activate_base_shard
          ensure_setup
          Thread.current[:shards][self.name.to_sym] = -1
        end

        def detect_corrupt_shards
          base_schema = extract_relevant_part_from_schema_definition(table_schema(table_name_without_shard))
          returning Array.new do |corrupt_shards|
            0.upto(shard_amount-1) do |shard|
              shard_schema = extract_relevant_part_from_schema_definition(table_schema(table_name_for_shard(shard)))
              corrupt_shards << shard if shard_schema!=base_schema or base_schema.blank?
            end
          end
        end

        def drop_shards(amount = nil)
          amount ||= detect_shard_amount_in_database
          ensure_positive_int('parameter for #drop_shards', amount)
          0.upto(amount-1) do |i|
            connection.execute("DROP TABLE #{table_name_for_shard(i)}")
          end
        end

        def table_name_with_shard
          ensure_setup
          shard = Thread.current[:shards][self.name.to_sym]

          return table_name_without_shard if @shard_amount==0 or shard == -1
          raise ArgumentError, 'No shard has been activated' unless shard
          table_name_for_shard(shard)
        end

        def detect_shard_amount_in_database
          result = connection.execute "SHOW TABLES LIKE '#{table_name_without_shard}%'"
          tables = []
          result.each do |row|
            tables << row[0].gsub(table_name_without_shard, '').to_i
          end
          result.free
          return 0 if tables.size<=1
          tables.sort.last.to_i + 1
        end

        def shard_levels
          return [] unless shard_amount > 0
          levels = []
          (0...shard_amount).each do |i|
            result = connection.execute "SELECT COUNT(*) FROM #{table_name_for_shard(i)}"
            result.each do |row|
              levels[i] = row[0].to_i
            end
          end
          levels
        end

        def ensure_setup
          raise ArgumentError, "You have to set #{self.name}.shard_amount" if @shard_amount.nil?
          Thread.current[:shards] ||= Hash.new
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
          schema
        rescue ActiveRecord::StatementInvalid
          ""
        ensure
          result.free if result
        end
        
        def extract_relevant_part_from_schema_definition(definition)
          definition.gsub!(/ AUTO_INCREMENT=[\d]+/, '')
          match = definition.match(/[^\(]+(.*)$/m)
          return match[1] if match
          ""
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
        
        def each_shard(shards = (0...@shard_amount))
          failed_shards = []
          shards.each do |i|
            ensure_positive_int("parameter for #each_shard", i)
            begin
              activate_shard(i)
              yield
            rescue
              failed_shards << i
            end
          end if block_given?
          return {:failed_shards => failed_shards}
        end
      end
    end
  end
end