require File.dirname(__FILE__) + '/../spec_helper'

describe "Acts as Muschable" do

  describe "integration tests with database access" do
    
    unless ENV['RUN_MUSCH_INTEGRATION_TESTS']=="true"
      puts <<-HELP
============== INTEGRATION TESTS =======================           <br>
 If you want to run integration tests, set                         <br>
 ENV['RUN_MUSCH_INTEGRATION_TESTS'] to 'true' and call             <br>
 rake spec again.                                                  <br>
                                                                   <br>
 Then make sure the mysql user rails:rails@localhost               <br>
 has all mysql privileges for database 'test' (should              <br>
 work out of the box if you have a rails user in mysql)            <br>
========================================================           <br>
      HELP
      break 
    end
    
    before(:all) do
      puts "\nRunning integration tests"
      @conn = MuschableModel.connection
    end
    
    it "should detect how many must be deleted with #detect_shard_amount_in_database when there are shards" do
      MuschableModel.detect_shard_amount_in_database.should == 4
    end
    
    it "should detect how many must be deleted with #detect_shard_amount_in_database when there are no shards" do
      OtherMuschableModel.detect_shard_amount_in_database.should == 0
    end
    
    it "should detect corrupt shards during #detect_corrupt_shards" do
      MuschableModel.shard_amount = 3
      MuschableModel.detect_corrupt_shards.should == [1,2]
    end
    
    it "should drop all shards during #drop_shards"
    
    it "should create all shards during #initialize_shards" do
      debugger
      OtherMuschableModel.detect_shard_amount_in_database.should == 0
      OtherMuschableModel.shard_amount = 10
      OtherMuschableModel.initialize_shards
      
      OtherMuschableModel.detect_shard_amount_in_database.should == 10
      OtherMuschableModel.detect_corrupt_shards.should be_blank
    end

    #
    # We're keepin' it clean (not) (but kinda)
    #
    after(:all) do
      ActiveRecord::Schema.define :version => 0 do
        [:muschable_models,
         :muschable_models0,
         :muschable_models1,
         :muschable_models3,
         :other_muschable_models].each do |table|
          drop_table table
        end
      end
      @conn.execute "DROP TABLE schema_migrations"
    end
  end
end