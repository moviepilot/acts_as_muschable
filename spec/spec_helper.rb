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