require 'property/role_module'
require 'property/stored_column'

module Property
  # This module lets you use a custom class to store a schema inside
  # the database. The custom class must also include StoredRole.
  module StoredSchema
    include SchemaModule

    def self.included(base)
      base.class_eval do
        attr_writer :class, :superschema
        # after_initialize :load_superschema #AR3.2

        # def load_superschema #AR3.2
        def after_initialize
          initialize_schema_module(:class => @class, :superschema => @superschema)
        end
      end
    end
  end
end
