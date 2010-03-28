module Property

  # This module is used when we need to access the properties in the properties storage model (to
  # compare versions for example). Including this module has the same effect as including 'Property'
  # but without the hooks (validation, save, etc).
  module Base
    def self.included(base)
      base.class_eval do
        include Attribute::Base
        include Serialization::JSON
        include Declaration::Base
        include Dirty
      end
    end
  end
end