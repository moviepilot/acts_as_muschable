require File.dirname(__FILE__) + '/../spec_helper'

describe "Acts as Muschable" do

  describe "integration tests with database access" do
    
    unless ENV['MUSCH_INTEGRATION_TESTS']=="true"
      puts <<-HELP
============== INTEGRATION TESTS ====================              <br>
 If you want to run integration tests, set                         <br>
 ENV['MUSCH_INTEGRATION_TESTS'] to 'true' and call                 <br>
 rake spec again.                                                  <br>
                                                                   <br>
 Then make sure the mysql user rails:rails@localhost               <br>
 has all mysql privileges for database 'test'                      <br>
=====================================================              <br>
      HELP
      break 
    end
    
    before(:all) do
      puts "\nRunning integration tests"
    end
    
    it "should detect corrupt shards during #assure_shards_health" do
    
    end

  end
end