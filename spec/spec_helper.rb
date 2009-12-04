ENV["RAILS_ENV"] = "test"

require 'rubygems'
require 'active_support'
require 'active_record'
require 'spec'

RAILS_DEFAULT_LOGGER = Logger.new(File.join(File.dirname(__FILE__), "debug.log"))

$: << File.join(File.dirname(__FILE__), '..', 'lib')
require File.join(File.dirname(__FILE__), '..', 'init')

if ENV['RUN_MUSCH_INTEGRATION_TESTS']=="true"
  ActiveRecord::Base.establish_connection(
    "adapter"  => "mysql",
    "database" => "test",
    "host"     => "localhost",
    "socket"   => "/tmp/mysql.sock",
    "port"     => 3306,
    "username" => "rails",
    "password" => "rails"
  )

  load(File.dirname(__FILE__) + '/schema.rb')
end

class MuschableModel < ActiveRecord::Base
  acts_as_muschable :shard_amount => 16
end

class OtherMuschableModel < ActiveRecord::Base
  acts_as_muschable :shard_amount => 16
end

class UnmuschableModel < ActiveRecord::Base
end

class MuschableAssociationBase < ActiveRecord::Base
  acts_as_muschable :shard_amount => 16
  
  belongs_to :muschable_belongs_to_association
  has_one :muschable_has_one_association
  has_many :muschable_has_many_associations
  has_and_belongs_to_many :muschable_habtm_associations
end

class MuschableBelongsToAssociation < ActiveRecord::Base
  has_many :muschable_association_bases
end

class MuschableHasOneAssociation < ActiveRecord::Base
  belongs_to :muschable_association_base
end

class MuschableHasManyAssociation < ActiveRecord::Base
  belongs_to :muschable_association_base
end

class MuschableHabtmAssociation < ActiveRecord::Base
  has_and_belongs_to_many :muschable_association_bases
end
  
# This is here so the schema definitions don't produce too much output
BEGIN {
  class<<Object
    def puts_with_crap_cleansing(msg)
      puts_without_crap_cleansing(msg) if ['-- ', '   ->'].reject{|⎮| msg.starts_with?(⎮)}.count == 2
    end
    alias_method :puts_without_crap_cleansing, :puts
    alias_method :puts, :puts_with_crap_cleansing
  end
}