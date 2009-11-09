require File.dirname(__FILE__) + '/../spec_helper'

describe "Acts as Muschable" do
  
  it "should be able to MuschableModel.set_shard"
  it "should return the correct MuschableModel.table_name according to shard"
  it "should throw an exception when MuschableModel.table_name is called before MuschableModel.set_shard"
  it "should create shards according to base_shard with MuschableModel.initialize_shards"
  
end