require 'rubygems'
require 'active_support'
require 'active_record'
require 'spec'

RAILS_DEFAULT_LOGGER = Logger.new(File.join(File.dirname(__FILE__), "debug.log"))

$: << File.join(File.dirname(__FILE__), '..', 'lib')
require File.join(File.dirname(__FILE__), '..', 'init')

class MuschableModel < ActiveRecord::Base
  acts_as_muschable :shard_amount => 16
end

class UnmuschableModel < ActiveRecord::Base
  
end