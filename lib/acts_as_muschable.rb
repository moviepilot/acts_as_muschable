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
        base.extend(ClassMethods)
      end
      
      module ClassMethods
        
        private 
        
        def acts_as_muschable(*args)
          self.class_eval <<-RUBY

            def self.shard_amount=(last)
              raise ArgumentError, 'Only integers are allowed as shard_amount' unless last.is_a?(Integer)
              @shard_amount = last
            end
            
            class << self; attr_reader :shard_amount end
            @shard_amount = nil

            def self.table_name_with_shard
              ensure_setup
              return table_name_without_shard if @shard_amount==0
              
              shard = Thread.current[:shards][self.name.to_sym]
              raise ArgumentError, 'No shard has been activated' unless shard
              "\#{table_name_without_shard}\#{shard}"
            end
            
            #  Sorry for the class << self block, we tried to keep it short.
            class << self
              alias_method_chain :table_name, :shard 
            end
            
            def self.activate_shard(shard)
              raise ArgumentError, 'Only integers are allowed as shard identifiers' unless shard.is_a?(Integer)
              ensure_setup
              Thread.current[:shards][self.name.to_sym] = shard.to_s
            end
            
            def self.ensure_setup
              raise ArgumentError, "You have to set #{self.class.name}.shard_amount" if @shard_amount.nil?
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
            def self.set_table_name(value = nil, &block)
              define_attr_method :table_name_without_shard, value, &block
            end
            
            self.shard_amount = #{args.last[:shard_amount] || 0 }
            
          RUBY
        end
      end
      
    end
  end
end