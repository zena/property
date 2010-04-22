require 'property/role_module'
require 'property/stored_column'

module Property
  # This module lets you use a custom class to store a set of property definitions inside
  # the database. For the rest, this class behaves just like Role.
  module StoredRole
    include RoleModule

    module ClassMethods
      def store_columns_in(columns_class, opts = {})
        columns_class = columns_class.to_s
        has_many :stored_columns, opts.merge(:class_name => columns_class)
      end
    end

    def self.included(base)
      base.extend ClassMethods

      base.class_eval do
        after_save :update_columns

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

        # Initialize a new role with the given name
        def initialize(*args)
          super
          initialize_role_module
        end
      end
    end # included

    # List all property definitions for the current role
    def columns
      load_columns_from_db unless @columns_from_db_loaded
      super
    end

    def property
      initialize_role_module unless @accessor_module
      super
    end


    private
      def load_columns_from_db
        initialize_role_module
        @columns_from_db_loaded = true
        @original_columns = {}
        stored_columns.each do |column|
          @original_columns[column.name] = column
          add_column(Property::Column.new(column.name, column.default, column.ptype, column.options))
        end
      end

      def update_columns
        @original_columns ||= {}
        stored_column_names  = @original_columns.keys
        defined_column_names = self.column_names

        new_columns     = defined_column_names - stored_column_names
        updated_columns = defined_column_names & stored_column_names
        # Not needed: there is no way to remove a property right now
        # deleted_columns = stored_column_names - defined_column_names

        new_columns.each do |name|
          ActiveRecord::Base.logger.warn "Creating #{name} column"
          stored_columns.create(:name => name, :ptype => columns[name].type)
        end

        updated_columns.each do |name|
          @original_columns[name].update_attributes(:name => name, :ptype => columns[name].type)
        end

        # Not needed: there is no way to remove a property right now
        # deleted_columns.each do |name|
        #   @original_columns[name].destroy!
        # end
      end
  end
end
