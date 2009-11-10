require File.dirname(__FILE__) + '/../spec_helper'

describe "Acts as Muschable" do
  
  describe "Changing active shards" do
    it "should throw an exception when MuschableModel.table_name is called before MuschableModel.set_shard" do
      lambda{ 
        MuschableModel.table_name
      }.should raise_error(ArgumentError, 'No shard has been activated')
    end
    
    it "should not affect UnMuschableModels" do
      UnmuschableModel.table_name.should == "unmuschable_models"
    end
    
    it "should be able to MuschableModel.activate_shard" do
      MuschableModel.should respond_to(:activate_shard)
    end
    
    it "should return the correct MuschableModel.table_name according to shard" do
      MuschableModel.activate_shard(0)
      MuschableModel.table_name.should == "muschable_models0"
      MuschableModel.activate_shard(1)
      MuschableModel.table_name.should == "muschable_models1"
    end
    
    it "should only accept numeric shard identifiers" do
      lambda{
        MuschableModel.activate_shard("0")
      }.should raise_error(ArgumentError, 'Only integers are allowed as shard identifiers')
    end
    
    it "should be somewhat thread safe" do
      threads = []
      300.times do
        threads << Thread.new do
          shard = rand(1_000_000)
          MuschableModel.activate_shard(shard)
          sleep(rand(15))
          MuschableModel.table_name.should == "muschable_models#{shard}"
        end
      end
      threads.each { |thread| thread.join }
    end
  end
  
  describe "Managing the amount of shards" do
    it "should have a method to set MuschableModel.shard_amount=" do
      MuschableModel.shard_amount = 1
      MuschableModel.shard_amount.should == 1
      MuschableModel.shard_amount = 15
      MuschableModel.shard_amount.should == 15
    end
    
    it "should do no sharding when MuschableModel.shard_amount is set to 0 (useful for test environments and such)" do
      MuschableModel.shard_amount = 0
      MuschableModel.table_name.should == "muschable_models"
    end
    
    it "should not accept non-integers as MuschableModel.shard_amount=" do
      lambda{
        MuschableModel.shard_amount = "15"
      }.should raise_error(ArgumentError, 'Only integers are allowed as shard_amount')
    end
    
    it "should not accept a shard identifier larger MuschableModel.shard_amount"
    it "should have a method MuschableModel.initialize_shards to drop(!!!) all existing shards and create new ones"
  end
end