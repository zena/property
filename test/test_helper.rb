require 'pathname'
$LOAD_PATH.unshift((Pathname(__FILE__).dirname +  '..' + 'lib').expand_path)

require 'logger'
require 'test/unit'
require 'shoulda'
require 'active_record'
require "active_support"
require 'database'
require 'property'
require 'shoulda_macros/serialization'
require 'shoulda_macros/role'
require 'shoulda_macros/index'

require 'fixtures'
require 'active_support/test_case'

