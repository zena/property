# We provide our own 'to_json' version because the default is just an alias for 'to_s' and we
# do not get the correct type back.
#
# In order to keep speed up, we have done some compromizes: all time values are considered to
# be UTC: we do not encode the timezone. We also ignore micro seconds.
class Time
  JSON_REGEXP = /\A(\d{4})-(\d\d)-(\d\d) (\d\d):(\d\d):(\d\d)\z/
  JSON_FORMAT = "%Y-%m-%d %H:%M:%S"

  def self.json_create(serialized)
    if serialized['data'] =~ JSON_REGEXP
      Time.utc $1.to_i, $2.to_i, $3.to_i, $4.to_i, $5.to_i, $6.to_i
    end
  end

  def to_json(*args)
    { 'json_class' => self.class.name, 'data' => strftime(JSON_FORMAT) }.to_json(*args)
  end
end
