RAILS_DEFAULT_LOGGER.silence do
  ActiveRecord::Schema.define :version => 0 do

    #
    #  Base table
    #
    create_table "muschable_models", :force => true do |t|
      t.integer  "id",        :limit => 11
      t.string   "name"
    end
    add_index "muschable_models", ["id"], :name => "index_on_id"

    #
    #  First shard, healthy
    #
    create_table "muschable_models0", :force => true do |t|
      t.integer  "id",        :limit => 11
      t.string   "name"
    end
    add_index "muschable_models0", ["id"], :name => "index_on_id"

    #
    #  Second shard, wrong column
    #
    create_table "muschable_models1", :force => true do |t|
      t.integer  "id",        :limit => 11
      t.string   "nume"
    end
    add_index "muschable_models1", ["id"], :name => "index_on_id"

    #
    #  Third shard, missing in action
    #

    #
    #  Fourth shard, missing index
    #
    create_table "muschable_models3", :force => true do |t|
      t.integer  "id",        :limit => 11
      t.string   "name"
    end

    #
    # Another base shard
    #
    create_table "other_muschable_models", :force => true do |t|
      t.integer  "id",        :limit => 11
      t.string   "name"
    end
    add_index "other_muschable_models", ["id"], :name => "index_on_id"
  end
end