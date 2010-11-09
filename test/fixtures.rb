
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
