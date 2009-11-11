require File.dirname(__FILE__) + '/../spec_helper'

describe "Integration tests with database access" do
  
  unless ENV['RUN_MUSCH_INTEGRATION_TESTS']=="true"
    puts <<-HELP
=============== INTEGRATION TESTS =======================          <br>
 If you want to run functional tests on your DB, set               <br>
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
  
  describe "shard management" do

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
    
    it "should drop all shards during #drop_shards(3)" do
      class YetAnotherMuschableModel < ActiveRecord::Base
        acts_as_muschable :shard_amount => 5
      end
      create_base_table_and_shards "yet_another_muschable_models", 10
      YetAnotherMuschableModel.detect_shard_amount_in_database.should == 10
      YetAnotherMuschableModel.drop_shards(10)
      YetAnotherMuschableModel.detect_shard_amount_in_database.should == 0
    end
    
    it "should drop all shards during #drop_shards (automatically guessing how many shards exist)" do
      class YetYetAnotherMuschableModel < ActiveRecord::Base
        acts_as_muschable :shard_amount => 5
      end
      create_base_table_and_shards "yet_yet_another_muschable_models", 15
      YetYetAnotherMuschableModel.activate_shard 0
      YetYetAnotherMuschableModel.detect_shard_amount_in_database.should == 15
      YetYetAnotherMuschableModel.drop_shards
      YetYetAnotherMuschableModel.detect_shard_amount_in_database.should == 0
    end
    
    it "should create all shards during #initialize_shards" do
      OtherMuschableModel.detect_shard_amount_in_database.should == 0
      OtherMuschableModel.shard_amount = 3
      OtherMuschableModel.initialize_shards
      
      OtherMuschableModel.detect_shard_amount_in_database.should == 3
      OtherMuschableModel.detect_corrupt_shards.should be_blank
    end

    #
    #  Drop all tables created during this test (i.e. have muschable in their name)
    after(:all) do
      @conn.execute "DROP TABLE schema_migrations"
      result = @conn.execute "SHOW TABLES LIKE '%muschable%'"
      result.each do |row|
        @conn.execute("DROP TABLE #{row[0]}")
      end
      result.free
    end

  end

  describe "objects living in different shards" do
    
    before(:all) do
      class MyMuschableModel < ActiveRecord::Base
        acts_as_muschable :shard_amount => 2
      end
      create_base_table_and_shards "my_muschable_models", 0
      MyMuschableModel.initialize_shards
    end
    
    it "should create different models in different shards" do
      MyMuschableModel.activate_shard 0
      model1_in_shard0 = MyMuschableModel.create :name => "model1_in_shard0"
      model2_in_shard0 = MyMuschableModel.create :name => "model2_in_shard0"
      MyMuschableModel.count.should == 2
      MyMuschableModel.find(model2_in_shard0.id).should == model2_in_shard0
      
      MyMuschableModel.activate_shard 1
      model1_in_shard1 = MyMuschableModel.create :name => "model1_in_shard1"
      MyMuschableModel.count.should == 1
      MyMuschableModel.destroy_all
      MyMuschableModel.count.should == 0

      MyMuschableModel.activate_shard 0
      MyMuschableModel.count.should == 2
    end
    
  end

end


#
#  Santa's little helper
#
def create_base_table_and_shards(table_name, shard_amount)
  ActiveRecord::Schema.define :version => 0 do
    create_table table_name, :force => true do |t|
      t.integer  "id",        :limit => 11
      t.string   "name"
    end
    add_index table_name, ["id"], :name => "index_on_id"
    
    0.upto(shard_amount-1) do |i|
      create_table "#{table_name}#{i}", :force => true do |t|
        t.integer  "id",                :limit => 11
        t.string   "name"
      end
      add_index "#{table_name}#{i}", ["id"], :name => "index_on_id"
    end
  end
end