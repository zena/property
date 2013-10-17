module Property
  class Error < Exception
  end
  
  # Raised in case property decoding fails and there is no invalid property default.
  class DecodingError < ::Property::Error
  end
end