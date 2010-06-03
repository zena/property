
class Employee < ActiveRecord::Base
  include Property
  property.string 'first_name', :default => '', :index => true
  property.string 'last_name',  :default => '', :index => true
  property.float  'age'

  def method_in_parent
  end
end

class Developer < Employee
  property.string 'language'
end

class WebDeveloper < Developer

end

class Version < ActiveRecord::Base
  attr_accessor :backup
  include Property
  property.string 'foo'
  # Other way to declare a string
  property do |p|
    p.string 'tic', 'comment'
  end
end

# To test custom class serialization
class Cat
  attr_accessor :name, :toy
  def self.json_create(data)
    Cat.new(data['name'], data['toy'])
  end

  def initialize(name, toy)
    @name, @toy = name, toy
  end

  def to_json(*args)
    { 'json_class' => self.class.to_s,
      'name' => @name, 'toy' => @toy
    }.to_json(*args)
  end

  def ==(other)
    other.kind_of?(Cat) && @name == other.name && @toy == other.toy
  end
end


class IdxEmployeesString < ActiveRecord::Base
end

class IdxEmployeesString < ActiveRecord::Base
end

class IdxEmployeesMlString < ActiveRecord::Base
end

class IdxEmployeesInteger < ActiveRecord::Base
end

class IdxEmployeesText < ActiveRecord::Base
end

class IdxEmployeesSpecial < ActiveRecord::Base
end

begin
  class PropertyMigration < ActiveRecord::Migration
    def self.down
      drop_table 'employees'
      drop_table 'versions'
      drop_table 'string_index'
    end

    def self.up
      create_table 'employees' do |t|
        t.string 'type'
        t.text   'properties'
      end

      create_table 'versions' do |t|
        t.integer 'employee_id'
        t.string  'properties'
        t.string  'title'
        t.string  'comment'
        t.string  'lang'
        t.timestamps
      end

      create_table 'dummies' do |t|
        t.text    'properties'
      end

      # index strings in employees
      create_table 'idx_employees_strings' do |t|
        t.integer 'employee_id'
        t.integer 'version_id'
        t.string  'key'
        t.string  'value'
      end

      # multilingual index strings in employees
      create_table 'idx_employees_ml_strings' do |t|
        t.integer 'employee_id'
        t.integer 'version_id'
        t.string  'lang'
        t.integer 'site_id'
        t.string  'key'
        t.string  'value'
      end

      # index strings in employees
      create_table 'idx_employees_specials' do |t|
        t.integer 'id'
        t.integer 'employee_id'
        t.string  'key'
        t.string  'value'
      end

      # index integer in employees
      create_table 'idx_employees_integers' do |t|
        t.integer 'employee_id'
        t.integer 'version_id'
        t.string  'key'
        t.integer 'value'
      end

      # index text in employees
      create_table 'idx_employees_texts' do |t|
        t.integer 'employee_id'
        t.string  'key'
        t.text    'value'
      end

      # custom or legacy index table
      create_table 'contacts' do |t|
        t.integer 'employee_id'
        t.string 'name'
        t.string 'other_name'
      end

      # Database stored role
      create_table 'roles' do |t|
        t.integer 'id'
        t.string 'name'
      end

      create_table 'columns' do |t|
        t.integer 'id'
        t.integer 'role_id'
        t.string 'name'
        # Property Type
        t.string 'ptype'
        # Indexed (we store an integer so that we can have multiple index types)
        t.string 'index'
      end
    end
  end

  ActiveRecord::Base.establish_connection(:adapter=>'sqlite3', :database=>':memory:')
  log_path = Pathname(__FILE__).dirname + '../log/test.log'
  Dir.mkdir(log_path.dirname) unless File.exist?(log_path.dirname)
  ActiveRecord::Base.logger = Logger.new(File.open(log_path, 'wb'))
  ActiveRecord::Migration.verbose = false
  #PropertyMigration.migrate(:down)
  PropertyMigration.migrate(:up)
  ActiveRecord::Migration.verbose = true
end