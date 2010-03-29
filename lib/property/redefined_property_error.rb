require 'property/error'

module Property
  # This error is raised when a behavior is included into a class and this inclusion
  # hides already defined properties.
  class RedefinedPropertyError < Property::Error
  end
end
