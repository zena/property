require 'pathname'
$LOAD_PATH.unshift((Pathname(__FILE__).dirname +  '..' + 'lib').expand_path)

require 'rubygems'
gem 'activerecord', '2.3.18'
require 'test/unit'
require 'shoulda'
require 'active_record'

require 'database'
require 'property'
require 'shoulda_macros/serialization'
require 'shoulda_macros/role'
require 'shoulda_macros/index'

require 'fixtures'
require 'active_support/test_case'
