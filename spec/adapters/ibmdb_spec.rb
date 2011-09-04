#!/usr/bin/env ruby
# coding: utf-8
#Author: Roy L Zuo (roylzuo at gmail dot com)
#Description: 

require File.join(File.dirname(File.expand_path(__FILE__)), 'spec_helper.rb')

IBMDB_DB = Sequel.connect(IBMDB_URL)

if IBMDB_DB.table_exists?(:test)
  IBMDB_DB.drop_table :test
end
INTEGRATION_DB = IBMDB_DB unless defined?(INTEGRATION_DB)

describe Sequel::Database do
  before do
    @db = IBMDB_DB
    @db.create_table(:escapetest){String :a}
    @ds = @db[:escapetest]
  end
  after do
    @db.drop_table(:escapetest)
  end
  
  specify "should correctly escape strings" do
    @ds.get("\\dingo".as(:a)) == "\\dingo"
  end

  specify "should correctly escape strings with quotes" do
    @ds.get("\\'dingo".as(:a)) == "\\'dingo"
  end

  specify "should properly escape binary data" do
    @ds.get("\1\2\3".to_sequel_blob.as(:a)) == "\1\2\3"
  end
end

describe Sequel::Database do
  before do
    @db = IBMDB_DB
    @db.create_table(:test){String :a}
    @ds = @db[:test]
  end

  after do
    @db.drop_table(:test)
  end
  
  specify "should provide disconnect functionality after preparing a connection" do
    @ds.prepare(:first, :a).call
    @db.disconnect
    @db.pool.size.should == 0
  end

  specify "should return version correct" do
    @db.db2_version.should match(/DB2 v/i)
  end
end

describe "Simple Dataset operations" do
  before do
    IBMDB_DB.create_table!(:items) do
      Integer :id, :primary_key => true
      Integer :number
    end
    @ds = IBMDB_DB[:items]
    @ds.insert(:number=>10, :id => 1 )
  end
  after do
    IBMDB_DB.drop_table(:items)
  end
  cspecify "should insert with a primary key specified", :mssql do
    @ds.insert(:id=>100, :number=>20)
    @ds.count.should == 2
    @ds.order(:id).all.should == [{:id=>1, :number=>10}, {:id=>100, :number=>20}]
  end
end

describe "Sequel::IBMDB.convert_smallint_to_bool" do
  before do
    @db = IBMDB_DB
    @db.create_table(:booltest){column :b, 'smallint'; column :i, 'integer'}
    @ds = @db[:booltest]
  end
  after do
    Sequel::IBMDB.convert_smallint_to_bool = true
    @db.drop_table(:booltest)
  end
  
  specify "should consider smallint datatypes as boolean if set, but not larger smallints" do
    @db.schema(:booltest, :reload=>true).first.last[:type].should == :boolean
    @db.schema(:booltest, :reload=>true).first.last[:db_type].should match /smallint/i
    Sequel::IBMDB.convert_smallint_to_bool = false
    @db.schema(:booltest, :reload=>true).first.last[:type].should == :integer
    @db.schema(:booltest, :reload=>true).first.last[:db_type].should match /smallint/i
  end
  
  specify "should return smallints as bools and integers as integers when set" do
    Sequel::IBMDB.convert_smallint_to_bool = true
    @ds.delete
    @ds << {:b=>true, :i=>10}
    @ds.all.should == [{:b=>true, :i=>10}]
    @ds.delete
    @ds << {:b=>false, :i=>0}
    @ds.all.should == [{:b=>false, :i=>0}]
    @ds.delete
    @ds << {:b=>true, :i=>1}
    @ds.all.should == [{:b=>true, :i=>1}]
  end

  specify "should return all smallints as integers when unset" do
    Sequel::IBMDB.convert_smallint_to_bool = false
    @ds.delete
    @ds << {:b=>true, :i=>10}
    @ds.all.should == [{:b=>1, :i=>10}]
    @ds.delete
    @ds << {:b=>false, :i=>0}
    @ds.all.should == [{:b=>0, :i=>0}]
    
    @ds.delete
    @ds << {:b=>1, :i=>10}
    @ds.all.should == [{:b=>1, :i=>10}]
    @ds.delete
    @ds << {:b=>0, :i=>0}
    @ds.all.should == [{:b=>0, :i=>0}]
  end
end
