require 'property/behavior_module'
require 'property/behavior_column'

module Property
  # This class lets you store a set of property definitions inside the database. For
  # the rest, this class behaves just like Behavior.
  class ActiveBehavior < ActiveRecord::Base
    include BehaviorModule
    has_many :behavior_columns
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

    # Initialize a new behavior with the given name
    def initialize(*args)
      super
      initialize_behavior_module
    end

    # List all property definitiosn for the current behavior
    def columns
      load_columns_from_db unless @columns_from_db_loaded
      super
    end

    def property
      initialize_behavior_module unless @accessor_module
      super
    end


    private
      def load_columns_from_db
        initialize_behavior_module
        @columns_from_db_loaded = true
        @stored_columns = {}
        behavior_columns.each do |column|
          @stored_columns[column.name] = column
          add_column(Property::Column.new(column.name, column.default, column.ptype, column.options))
        end
      end

      def update_columns
        @stored_columns ||= {}
        stored_column_names  = @stored_columns.keys
        defined_column_names = self.column_names

        new_columns     = defined_column_names - stored_column_names
        updated_columns = defined_column_names & stored_column_names
        # Not needed: there is no way to remove a property right now
        # deleted_columns = stored_column_names - defined_column_names

        new_columns.each do |name|
          behavior_columns.create(:name => name, :ptype => columns[name].type)
        end

        updated_columns.each do |name|
          @stored_columns[name].update_attributes(:name => name, :ptype => columns[name].type)
        end

        # Not needed: there is no way to remove a property right now
        # deleted_columns.each do |name|
        #   @stored_columns[name].destroy!
        # end
      end
  end
end
