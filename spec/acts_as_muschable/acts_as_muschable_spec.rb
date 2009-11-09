require File.dirname(__FILE__) + '/../spec_helper'

describe "Acts as Muschable" do
  
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
    MuschableModel.activate_shard("0")
    MuschableModel.table_name.should == "muschable_models0"
    MuschableModel.activate_shard(1)
    MuschableModel.table_name.should == "muschable_models1"
  end
  
end