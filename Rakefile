require 'pathname'
$LOAD_PATH.unshift((Pathname(__FILE__).dirname +  'lib').expand_path)

require 'property'
require 'rake'
require 'rake/testtask'

Rake::TestTask.new(:test) do |test|
  test.libs     << 'lib' << 'test'
  test.pattern  = 'test/**/**_test.rb'
  test.verbose  = true
end

begin
  require 'rcov/rcovtask'
  Rcov::RcovTask.new do |test|
    test.libs << 'test' << 'lib'
    test.pattern = 'test/**/**_test.rb'
    test.verbose = true
    test.rcov_opts = ['-T', '--exclude-only', '"test\/,^\/"']
  end
rescue LoadError
  task :rcov do
    abort "RCov is not available. In order to run rcov, you must: sudo gem install rcov"
  end
end

task :default => :test


# GEM management
begin
  require 'jeweler'
  Jeweler::Tasks.new do |gemspec|
    gemspec.name = 'property'
    gemspec.summary = 'model properties wrap into a single database column'
    gemspec.description = "Wrap model properties into a single database column and declare properties from within the model."
    gemspec.email = "gaspard@teti.ch"
    gemspec.homepage = "http://zenadmin.org/635"
    gemspec.authors = ['Renaud Kern', 'Gaspard Bucher']
    gemspec.version = Property::VERSION
    gemspec.rubyforge_project = 'property'

    # Gem dependecies
    gemspec.add_development_dependency('shoulda')
    gemspec.add_dependency('activerecord')
  end
rescue LoadError
  puts "Jeweler not available. Gem packaging tasks not available."
end
#