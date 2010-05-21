require 'test_helper'
require 'fixtures'

class IndexForeignTest < ActiveSupport::TestCase
  class IndexedStringEmp < ActiveRecord::Base
    set_table_name :i_string_employees
  end

  class IndexedIntegerEmp < ActiveRecord::Base
    set_table_name :i_integer_employees
  end

  class IndexedTextEmp < ActiveRecord::Base
    set_table_name :i_text_employees
  end

  class Version < ActiveRecord::Base
    belongs_to :contact, :class_name => 'IndexForeignTest::Contact',
               :foreign_key => 'employee_id'
  end

  class Contact < ActiveRecord::Base
    set_table_name :employees

    has_many :versions, :class_name => 'IndexForeignTest::Version'
    def version
      @version ||= begin
        if new_record?
          versions.build
        else
          Version.first(:conditions => ['employee_id = ?', self.id]) || versions.build
        end
      end
    end

    def new_version!
      @version = versions.build
    end

    def lang=(l)
      version.lang = l
    end

    include Property
    store_properties_in :version

    property do |p|
      p.string  'name'
      p.integer 'age', :indexed => true
      p.string  'gender'

      p.index(:string) do |r| # r = record
        {
          "high"                   => "gender:#{r.gender} age:#{r.age} name:#{r.name}",
          "name_#{r.version.lang}" => r.name, # multi-lingual index
        }
      end
    end

    def index_reader(group_name)
      {'version_id' => version.id}
    end

    # Foreign index: we store the 'employee_id' in the index to get back directly to non-versioned class Contact (through employee_id key).
    def index_writer(group_name)
      {'version_id' => version.id, 'employee_id' => self.id}
    end
  end

  context 'A class with foreign index definition' do
    subject do
      Contact
    end

    context 'on record creation' do
      should 'create index entries' do
        assert_difference('IndexedStringEmp.count', 2) do
          Contact.create('name' => 'Juan', 'lang' => 'es', 'gender' => 'M', 'age' => 34)
        end
      end

      should 'store key and value pairs linked to the model' do
        person = Contact.create('name' => 'Juan', 'lang' => 'es', 'gender' => 'M', 'age' => 34)
        high_index, name_index = IndexedStringEmp.all(:conditions => {:version_id => person.version.id}, :order => 'key asc')
        assert_equal 'high', high_index.key
        assert_equal 'gender:M age:34 name:Juan', high_index.value
        assert_equal 'name_es', name_index.key
        assert_equal 'Juan', name_index.value
      end

      should 'store key and value pairs linked to the foreign model' do
        person = Contact.create('name' => 'Juan', 'lang' => 'es', 'gender' => 'M', 'age' => 34)
        high_index, name_index = IndexedStringEmp.all(:conditions => {:employee_id => person.id}, :order => 'key asc')
        assert_equal 'high', high_index.key
        assert_equal 'gender:M age:34 name:Juan', high_index.value
        assert_equal 'name_es', name_index.key
        assert_equal 'Juan', name_index.value
      end
    end

    context 'on record update' do
      setup do
        @person = Contact.create('name' => 'Juan', 'lang' => 'es', 'gender' => 'M', 'age' => 34)
      end

      should 'update index entries' do
        high_index, name_index = IndexedStringEmp.all(:conditions => {:employee_id => @person.id}, :order => 'key asc')
        assert_difference('IndexedStringEmp.count', 0) do
          @person.update_attributes('name' => 'Xavier')
        end

        high_index = IndexedStringEmp.find(high_index.id) # reload (make sure the record has been updated, not recreated)
        name_index = IndexedStringEmp.find(name_index.id) # reload (make sure the record has been updated, not recreated)

        assert_equal 'high', high_index.key
        assert_equal 'gender:M age:34 name:Xavier', high_index.value
        assert_equal 'name_es', name_index.key
        assert_equal 'Xavier', name_index.value
      end

      context 'with key alterations' do
        should 'remove and create new keys' do
          high_index, name_index = IndexedStringEmp.all(:conditions => {:employee_id => @person.id}, :order => 'key asc')
          assert_difference('IndexedStringEmp.count', 0) do
            @person.update_attributes('lang' => 'en', 'name' => 'John')
          end

          assert IndexedStringEmp.find(high_index.id)
          assert_nil IndexedStringEmp.find_by_id(name_index.id)

          high_index, name_index = IndexedStringEmp.all(:conditions => {:employee_id => @person.id}, :order => 'key asc')

          assert_equal 'high', high_index.key
          assert_equal 'gender:M age:34 name:John', high_index.value
          assert_equal 'name_en', name_index.key
          assert_equal 'John', name_index.value
        end
      end
    end

    context 'on record update with a new version' do
      should 'create new index entries' do
        @person = Contact.create('name' => 'Juan', 'lang' => 'es', 'gender' => 'M', 'age' => 34)
        high_index1, name_index1 = IndexedStringEmp.all(:conditions => {:version_id => @person.version.id}, :order => 'key asc')
        @person.new_version!
        assert_difference('IndexedStringEmp.count', 2) do
          @person.update_attributes('name' => 'John', 'lang' => 'en')
        end

        high_index, name_index = IndexedStringEmp.all(:conditions => {:version_id => @person.version.id}, :order => 'key asc')
        assert_not_equal high_index1.id, high_index.id
        assert_not_equal name_index1.id, name_index.id

        assert_equal 'high', high_index.key
        assert_equal 'gender:M age:34 name:John', high_index.value
        assert_equal 'name_en', name_index.key
        assert_equal 'John', name_index.value
      end

      # ========== The context below is not really a test: it is used to example the index usage to sort
      context 'in different languages' do
        setup do
          Contact.destroy_all
          # People: Jean (John) and Jim
          # sort order:
          # fr: Jean, Jim
          # en: Jim, John
          @jean = Contact.create('name' => 'Jean', 'lang' => 'fr', 'gender' => 'M', 'age' => 34)
          @jean.new_version!
          @jean.update_attributes('name' => 'John', 'lang' => 'en')
          @jim  = Contact.create('name' => 'Jim', 'lang' => 'fr', 'gender' => 'M', 'age' => 17)
          @jim.new_version!
          @jim.update_attributes('name' => 'Jim', 'lang' => 'en')
        end

        should 'create index entries to sort multilingual values' do
          people_fr = Contact.find(:all, :joins  => "INNER JOIN i_string_employees AS ise ON ise.employee_id = employees.id AND ise.key = 'name_fr'",
                                          :order => "ise.value asc")

          people_en = Contact.find(:all, :joins  => "INNER JOIN i_string_employees AS ise ON ise.employee_id = employees.id AND ise.key = 'name_en'",
                                          :order => "ise.value asc")

          assert_equal [@jean.id, @jim.id], people_fr.map {|r| r.id}
          assert_equal [@jim.id, @jean.id], people_en.map {|r| r.id}
        end
      end

      # ========== The context below is not really a test: it is used to example the index usage to sort
      context 'in different languages with missing translations' do
        setup do
          Contact.destroy_all
          # People: Jean (John) and Jim
          # sort order:
          # fr: Jean, Jim
          # en: Jim, John
          @jean = Contact.create('name' => 'Jean', 'lang' => 'fr', 'gender' => 'M', 'age' => 34)
          @jean.new_version!
          @jean.update_attributes('name' => 'John', 'lang' => 'en')
          @jim  = Contact.create('name' => 'Jim', 'lang' => 'en', 'gender' => 'M', 'age' => 17)
          # no version for @jim in 'fr'
        end

        should 'create index entries to sort multilingual values' do
          people_fr = Contact.find(:all, :joins  => "INNER JOIN i_string_employees AS ise ON ise.employee_id = employees.id AND ise.key = 'name_fr'",
                                          :order => "ise.value asc")

          people_en = Contact.find(:all, :joins  => "INNER JOIN i_string_employees AS ise ON ise.employee_id = employees.id AND ise.key = 'name_en'",
                                          :order => "ise.value asc")

          # This is what we would like to have (once we have found an SQL trick to get the record in 'en')
          # assert_equal [@jean.id, @jim.id], people_fr.map {|r| r.id}

          # But this is what we get
          assert_equal [@jean.id], people_fr.map {|r| r.id}

          assert_equal [@jim.id, @jean.id], people_en.map {|r| r.id}
        end
      end
    end

    context 'on record destruction' do
      should 'remove index entries' do
        person = Contact.create('name' => 'Juan', 'lang' => 'es', 'gender' => 'M', 'age' => 34)
        assert_difference('IndexedStringEmp.count', -2) do
          assert_difference('IndexedIntegerEmp.count', -1) do
            person.destroy
          end
        end
      end
    end
  end
end