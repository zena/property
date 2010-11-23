require 'property/role_module'
require 'property/stored_column'

module Property
  # This module lets you use a custom class to store a set of property definitions inside
  # the database. For the rest, this class behaves just like Role.
  #
  # Once this module is included, you need to set the has_many association to the class that
  # contains the columns definitions with something like:
  #
  #   stored_columns_class NameOfColumnsClass
  module StoredRole
    include RoleModule

    module ClassMethods
      def stored_columns_class(columns_class)
        has_many :stored_columns, :class_name => columns_class
      end
    end

    def self.included(base)
      base.class_eval do
        after_save :update_columns
        validates_presence_of :name
        
        extend ClassMethods

        def self.new(arg, &block)
          unless arg.kind_of?(Hash)
            arg = {:name => arg}
          end

          if block_given?
            obj = super(arg) do
              # Dummy block to hide our special property declaration block
            end

            obj.property(&block)
          else
            obj = super(arg)
          end

          obj
        end
      end
    end # included

    # Get all property definitions defined for this role
    def defined_columns
      load_columns_from_db unless @columns_from_db_loaded
      super
    end

    def property
      super
    end

    # Overwrite name reader in RoleModule
    def name
      self[:name]
    end


    private
      def load_columns_from_db
        @columns_from_db_loaded = true
        @original_columns = {}
        stored_columns.each do |column|
          @original_columns[column.name] = column
          add_column(Property::Column.new(column.name, column.default, column.ptype, column.options.merge(:role => self)))
        end
      end

      def update_columns
        return unless @defined_columns # no change
        unless @original_columns
          load_columns_from_db
        end
        stored_column_names  = @original_columns.keys
        defined_column_names = column_names

        new_columns     = defined_column_names - stored_column_names
        updated_columns = defined_column_names & stored_column_names
        # Not needed: there is no way to remove a property right now
        # deleted_columns = stored_column_names - defined_column_names

        new_columns.each do |name|
          ActiveRecord::Base.logger.warn "Creating #{name} column"
          stored_columns.create(:name => name, :ptype => columns[name].type.to_s)
        end

        updated_columns.each do |name|
          @original_columns[name].update_attributes(:name => name, :ptype => columns[name].type.to_s)
        end

        # Not needed: there is no way to remove a property right now
        # deleted_columns.each do |name|
        #   @original_columns[name].destroy!
        # end
      end
  end
end
