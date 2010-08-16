require 'spec_helper'

class CsvSquidUser
  include CsvSquid
  
  COLUMNS = %w(id name age)
  
  attr_accessor *COLUMNS

  def self.human_attribute_name(attribute)
    attribute.to_s.humanize
  end

  def initialize(params={})
    params.each { |key, value| self.send("#{key}=", value); }
    self
  end

  def attributes
    COLUMNS.inject({}) { |attributes, attribute| attributes.merge(attribute => send(attribute)) }
  end

  def is_old?
    age > 40
  end

  def profile_item
    profile_items.first
  end

  def profile_items
    [CsvSquidProfileItem.new(:id => 1, :name => "First Name", :value => "Person One"), CsvSquidProfileItem.new(:id => 2, :name => "Last Name", :value => "Smith")]
  end

  def favorite
    favorites.first
  end
  def favorites
    [CsvSquidFavorite.new(:id => 1, :name => "Pizza"), CsvSquidFavorite.new(:id => 2, :name => "Beer")]
  end
end

class CsvSquidProfileItem
  COLUMNS = %w{id name value}
  attr_accessor *COLUMNS
  def self.human_attribute_name(attribute); attribute.to_s.humanize; end
  def initialize(params={}); params.each {|k,v| self.send("#{k}=", v) }; self; end
  
  # Returns a hash of keys as attribute names corresponding to values.
  def attributes; COLUMNS.inject({}) {|as,a| as.merge(a => send(a))}; end
  def my_label; "#{name.underscore}"; end
  def favorite
    CsvSquidFavorite.new(:id => 1, :name => "Pizza")
  end

  def color
    colors.first
  end

  def colors
    [CsvSquidColor.new(:name => "Red"), CsvSquidColor.new(:name => "Blue")]
  end

end

class CsvSquidFavorite
  COLUMNS = %w{id name}
  attr_accessor *COLUMNS
  def self.human_attribute_name(attribute); attribute.to_s.humanize; end
  def initialize(params={}); params.each {|k,v| self.send("#{k}=", v) }; self; end
  def attributes; COLUMNS.inject({}) {|as,a| as.merge(a => send(a))}; end
  
  def color
    colors.first
  end

  def colors
    [CsvSquidColor.new(:name => "Red"), CsvSquidColor.new(:name => "Blue")]
  end

end

class CsvSquidColor
  COLUMNS = %w{name}
  attr_accessor *COLUMNS
  def self.human_attribute_name(attribute); attribute.to_s.humanize; end
  def initialize(params={}); params.each {|k,v| self.send("#{k}=", v) }; self; end
  def attributes; COLUMNS.inject({}) {|as,a| as.merge(a => send(a))}; end
end

describe "CsvSquid" do
  describe "#to_csv" do
    
    # Setup user objects and their attributes used during test
    let(:users) do 
      [ CsvSquidUser.new(:id => 1, :name => 'Ary', :age => 25), 
        CsvSquidUser.new(:id => 2, :name => 'Nati', :age => 22) ]
    end


    it "returns an empty string when empty" do
      [].to_csv.should == ""
    end

    it "converts the array to csv fully" do
      users.to_csv.should == "Age,Id,Name\n25,1,Ary\n22,2,Nati\n"

    end

    it "returns unique rows only" do
      # it should make output unique before rendering.
      users.to_csv(:only => [], :include => [:favorites, :profile_items]).should ==
        "Favorite,Favorite Name,Profile Item,Profile Item Name,Profile Item Value\n" +
        "1,Pizza,1,First Name,Person One\n" +
        "1,Pizza,2,Last Name,Smith\n" +
        "2,Beer,1,First Name,Person One\n" +
        "2,Beer,2,Last Name,Smith\n"
    end

    context "with :headers => false" do
      it "leaves off the header row" do
        users.to_csv(:headers => false).should == "25,1,Ary\n22,2,Nati\n"
      end
    end

    context "with :only" do
      it "gives name when asked" do
        users.to_csv(:only => :name).should == "Name\nAry\nNati\n"
      end
    end

    context "with empty :only" do
      it "returns nothing" do
        users.to_csv(:only => "").should ==  ""
      end
    end

    context "with :only and wrong column names" do
      it "ignores the bad column name" do
        users.to_csv(:only => [:name, :yoyo]).should == "Name\nAry\nNati\n"
      end
    end

    context "with :except" do
      it "leaves off the excepted columns" do
        users.to_csv(:except => [:id, :name]).should == "Age\n25\n22\n"
      end
    end

    context "with :except and :only" do
      it "prefers only" do
        users.to_csv(:except => [:id, :name], :only => :name).should == "Name\nAry\nNati\n"
      end
    end

    context "with :methods" do
      it "includes the output from the methods listed" do
        users.to_csv(:methods => [:is_old?]).should == "Age,Id,Is Old?,Name\n25,1,false,Ary\n22,2,false,Nati\n"
      end
    end
   
    context "with :include" do
      it "should include all the attributes from the associated object" do
        users.to_csv(:include => :profile_item).should == "Age,Id,Name,Profile" +
          " Item,Profile Item Name,Profile Item Value\n25,1,Ary,1,First" +
          " Name,Person One\n22,2,Nati,1,First Name,Person One\n" 
      end

      it "should allow arrays of associated objects" do
        users.to_csv(
          :include => [:profile_item, :favorite]
        ).should == "Age,Id,Name,Favorite,Favorite Name,Profile Item," +
          "Profile Item Name,Profile Item Value\n25,1,Ary,1,Pizza,1,First" + 
          " Name,Person One\n22,2,Nati,1,Pizza,1,First Name,Person One\n" 
      end

      it "should allow hashes with further options" do
        users.to_csv(
          :include => {
            :profile_item => {
              :methods => [:my_label], 
              :only => ""
            }
          }
        ).should == "Age,Id,Name,Profile Item My Label\n25,1,Ary,first name\n22,2,Nati,first name\n"
      end
      
      it "should allow really complex options" do
        users.to_csv(
          :only => [:name],
          :include => {
            :profile_item => { :only   => [:name] },
            :favorite     => { :except => [:id]   }
          }
        ).should == "Name,Favorite Name,Profile Item Name\nAry,Pizza,First Name\nNati,Pizza,First Name\n"
      end

      it "accepts objects instead of association symbols" do
        users.to_csv(
          :include => {
            CsvSquidFavorite.new(:id => 5, :name => "Cheese") => {:only => :name}
          }
        ).should == "Age,Id,Name,To Csv Favorite Name\n25,1,Ary,Cheese\n22,2,Nati,Cheese\n"
      end

      it "should allow nested includes of associated objects" do
        users.to_csv(:include => {:profile_item => {:include => :favorite} } ).should ==
          "Age,Id,Name,Profile Item,Profile Item Name,Profile" +
          " Item Value,Favorite,Favorite Name\n25,1,Ary,1,First Name," +
          "Person One,1,Pizza\n22,2,Nati,1,First Name,Person One,1,Pizza\n"
      end
      it "should allow nested includes of associated arrays objects" do
        users.to_csv(:include => {:favorites => {:include => :colors}}).should ==
          "Age,Id,Name,Favorite,Favorite Name,Color Name\n" +
          "25,1,Ary,1,Pizza,Red\n" +
          "25,1,Ary,1,Pizza,Blue\n" +
          "25,1,Ary,2,Beer,Red\n" +
          "25,1,Ary,2,Beer,Blue\n" +
          "22,2,Nati,1,Pizza,Red\n" +
          "22,2,Nati,1,Pizza,Blue\n" +
          "22,2,Nati,2,Beer,Red\n" + 
          "22,2,Nati,2,Beer,Blue\n"

      end

      it "should allow complex nested includes of different types" do
        users.to_csv(:only => :name,
                     :include => {:favorite => {:only => :name}, 
                                  :profile_item => {:only => :name, 
                                                    :include => {:colors => {:only => :name}}}} ).should ==
          "Name,Favorite Name,Profile Item Name,Color Name\n" +
          "Ary,Pizza,First Name,Red\n" +
          "Ary,Pizza,First Name,Blue\n" +
          "Nati,Pizza,First Name,Red\n" +
          "Nati,Pizza,First Name,Blue\n"
      end
    end #context "with :include"

    context "with :column_order" do
      it "should list columns in specified order" do
        users.to_csv(:column_order => [:name, :age, :id]).should ==
          "Name,Age,Id\n" +
          "Ary,25,1\n" +
          "Nati,22,2\n"
      end

      it "should list columns in specified order when including associated objects" do
        users.to_csv(:include => :profile_item, 
                     :column_order => [:name, :profile_item_name, :age, \
                                       :profile_item_id, :id, \
                                       :profile_item_value]).should ==
          "Name,Profile Item Name,Age,Profile Item,Id,Profile Item Value\n" +
          "Ary,First Name,25,1,1,Person One\n" +
          "Nati,First Name,22,1,2,Person One\n"
      end
    
      it "should leave off remaining columns not specified by column order" do
        users.to_csv(:include => [:favorites, :profile_items], :column_order => [:profile_item_name, :favorite_name, :name]).should ==
          "Profile Item Name,Favorite Name,Name\n" +
          "First Name,Pizza,Ary\n" +
          "Last Name,Pizza,Ary\n" +
          "First Name,Beer,Ary\n" +
          "Last Name,Beer,Ary\n" +
          "First Name,Pizza,Nati\n" +
          "Last Name,Pizza,Nati\n" +
          "First Name,Beer,Nati\n" +
          "Last Name,Beer,Nati\n"       
      end
    end

    # Allow support for options[:column_names = {:name => "value",...}]
    context "with :column_names" do

      it "should allow renaming of all column names" do
        users.to_csv(:column_names => {:name => "NAME", :age => "AGE", :id => "ID"}).should ==
          "AGE,ID,NAME\n" +
          "25,1,Ary\n" +
          "22,2,Nati\n"
      end

      it "should leave off remaining columns not specified by column order" do
        users.to_csv(:include => [:favorites, :profile_items], :column_order => [:profile_item_name, :favorite_name, :name], :column_names => {:profile_item_name => "ProfName", :favorite_name => "FavNam", :name => "Name"}).should ==
          "ProfName,FavNam,Name\n" +
          "First Name,Pizza,Ary\n" +
          "Last Name,Pizza,Ary\n" +
          "First Name,Beer,Ary\n" +
          "Last Name,Beer,Ary\n" +
          "First Name,Pizza,Nati\n" +
          "Last Name,Pizza,Nati\n" +
          "First Name,Beer,Nati\n" +
          "Last Name,Beer,Nati\n"       
      end
    end


    context "with an activerecord object" do
      first_name = Faker::Name.first_name
      last_name = Faker::Name.last_name
      email = "#{first_name}.#{last_name}@mail.com"

      subject { Factory.create(:customer,
                               :first_name => first_name, 
                               :last_name => last_name, 
                               :email => email) }                                

      it "should allow option :only" do
        subject.to_csv(:only => [:first_name,:last_name, :email]).should == 
          "Email,First Name,Last Name\n#{email},#{first_name},#{last_name}\n"
      end
     
      it "should allow option to leave off header row" do
        subject.to_csv(:headers => false, :only => [:email]).should ==
        "#{email}\n"
      end

      it "should return nothing when asked nicely" do
        subject.to_csv(:only => "").should == ""
      end

      it "should leave off specific columns when ask politely" do
        subject.to_csv(:except => [:buydotcom_username, 
                                   :amazon_username,
                                   :ebay_username,
                                   :updated_at,
                                   :created_at,
                                   :credit_balance_cents,
                                   :id,
                                   :infopia_customer_id,
                                   :default_address_id]).should ==
          "Email,First Name,Last Name\n#{email},#{first_name},#{last_name}\n"
      end

      it "leaves off bad column names" do
        subject.to_csv(:only => [:first_name, :yoyo]).should == 
          "First Name\n#{first_name}\n"
      end
      
      it "prefers only" do
        subject.to_csv(:except => [:id, :last_name], 
                       :only => :last_name).should == 
                       "Last Name\n#{last_name}\n"
      end

      it "includes the output from the methods listed" do
        subject.to_csv(:methods => [:name], 
                       :only => [:email]).should == 
                       "Email,Name\n#{email},#{first_name} #{last_name}\n"
      end

      it "should allow ordering of columns and leave off columns not " + 
         "specified" do
        subject.to_csv(:column_order => [:last_name, :email]).should ==
          "Last Name,Email\n#{last_name},#{email}\n"
        
        subject.to_csv(:column_order => 
                       [:first_name, :email, :last_name]).should ==
          "First Name,Email,Last Name\n#{first_name},#{email},#{last_name}\n"
      end

      it "should allow renaming of columns" do
        subject.to_csv(:column_names => {:email => "Mail",
                                         :first_name => "Name-First",
                                         :last_name => "Name-Last"},
                       :only => [:email, :first_name, :last_name]).should ==
          "Mail,Name-First,Name-Last\n#{email},#{first_name},#{last_name}\n"
      end

    end #context

  end
end

# Use subject.to_csv(...).should =~ /^ <some_regex> $/  for regex matching.
