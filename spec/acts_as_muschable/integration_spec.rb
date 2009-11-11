require File.dirname(__FILE__) + '/../spec_helper'

describe "Acts as Muschable" do

  describe "integration tests with database access" do
    
    unless ENV['RUN_MUSCH_FUNCTIONAL_TESTS']=="true"
      puts <<-HELP
=============== FUNCTIONAL TESTS =======================           <br>
 If you want to run functional tests on your DB, set               <br>
 ENV['RUN_MUSCH_FUNCTIONAL_TESTS'] to 'true' and call              <br>
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
    
    it "should drop all shards during #drop_shards(3)"
    
    it "should drop all shards during #drop_shards (automatically guessing how many shards exist)"
    
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
end

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