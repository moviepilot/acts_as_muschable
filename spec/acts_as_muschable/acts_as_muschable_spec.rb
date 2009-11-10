require File.dirname(__FILE__) + '/../spec_helper'

describe "Acts as Muschable" do
  
  describe "changing active shards" do
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
    
    it "should only accept positive numeric shard identifiers" do
      lambda{
        MuschableModel.activate_shard("0")
      }.should raise_error(ArgumentError, 'Only positive integers are allowed as shard identifier')
      lambda{
        MuschableModel.activate_shard(-1)
      }.should raise_error(ArgumentError, 'Only positive integers are allowed as shard identifier')
    end
    
    it "should be somewhat thread safe" do
      MuschableModel.shard_amount = 1_000_000
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
  
  describe "managing the amount of shards" do
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
      }.should raise_error(ArgumentError, 'Only positive integers are allowed as shard_amount')
      lambda{
        MuschableModel.shard_amount = -1
      }.should raise_error(ArgumentError, 'Only positive integers are allowed as shard_amount')
    end
    
    it "should not accept a shard identifier larger MuschableModel.shard_amount" do
      MuschableModel.shard_amount = 16
      lambda{
        MuschableModel.activate_shard(16)
      }.should raise_error(ArgumentError, "Can't activate shard, out of range. Adjust MuschableModel.shard_amount=")
    end
    
    it "should have a method MuschableModel.initialize_shards to create MuschableModel.shard_amount new shards" do
      MuschableModel.shard_amount=32
      connection = mock("Connection")
      MuschableModel.should_receive(:connection).once.and_return connection
      0.upto(31) do |i|
        query = "CREATE TABLE muschable_models#{i} LIKE muschable_models"
        connection.should_receive(:execute).with(query).once
      end
      
      MuschableModel.initialize_shards
    end
    
    
    it "should have a method MuschableModel.drop_shards(15) to drop shards 0...15"
    it "should have a method MuschableModel.assure_shard_health that goes through all shards and makes sure their structure equals that of the base table"
  end
end