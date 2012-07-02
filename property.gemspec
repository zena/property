# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run 'rake gemspec'
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{property}
  s.version = "2.3.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Renaud Kern", "Gaspard Bucher"]
  s.date = %q{2012-07-02}
  s.description = %q{Wrap model properties into a single database column and declare properties from within the model.}
  s.email = %q{gaspard@teti.ch}
  s.extra_rdoc_files = [
    "README.rdoc"
  ]
  s.files = [
    "History.txt",
    "MIT-LICENSE",
    "README.rdoc",
    "Rakefile",
    "generators/property/property_generator.rb",
    "lib/property.rb",
    "lib/property/attribute.rb",
    "lib/property/base.rb",
    "lib/property/column.rb",
    "lib/property/core_ext/time.rb",
    "lib/property/db.rb",
    "lib/property/declaration.rb",
    "lib/property/dirty.rb",
    "lib/property/error.rb",
    "lib/property/index.rb",
    "lib/property/properties.rb",
    "lib/property/redefined_method_error.rb",
    "lib/property/redefined_property_error.rb",
    "lib/property/role.rb",
    "lib/property/role_module.rb",
    "lib/property/schema.rb",
    "lib/property/schema_module.rb",
    "lib/property/serialization/json.rb",
    "lib/property/serialization/marshal.rb",
    "lib/property/serialization/yaml.rb",
    "lib/property/stored_column.rb",
    "lib/property/stored_role.rb",
    "lib/property/stored_schema.rb",
    "lib/property/version.rb",
    "property.gemspec",
    "test/database.rb",
    "test/fixtures.rb",
    "test/shoulda_macros/index.rb",
    "test/shoulda_macros/role.rb",
    "test/shoulda_macros/serialization.rb",
    "test/test_helper.rb",
    "test/unit/property/attribute_test.rb",
    "test/unit/property/base_test.rb",
    "test/unit/property/column_test.rb",
    "test/unit/property/declaration_test.rb",
    "test/unit/property/dirty_test.rb",
    "test/unit/property/index_complex_test.rb",
    "test/unit/property/index_custom_test.rb",
    "test/unit/property/index_field_test.rb",
    "test/unit/property/index_foreign_test.rb",
    "test/unit/property/index_simple_test.rb",
    "test/unit/property/role_test.rb",
    "test/unit/property/stored_role_test.rb",
    "test/unit/property/validation_test.rb",
    "test/unit/serialization/json_test.rb",
    "test/unit/serialization/marshal_test.rb",
    "test/unit/serialization/yaml_test.rb"
  ]
  s.homepage = %q{http://zenadmin.org/635}
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{property}
  s.rubygems_version = %q{1.6.2}
  s.summary = %q{model properties wrap into a single database column}

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<shoulda>, [">= 0"])
      s.add_runtime_dependency(%q<activerecord>, [">= 0"])
    else
      s.add_dependency(%q<shoulda>, [">= 0"])
      s.add_dependency(%q<activerecord>, [">= 0"])
    end
  else
    s.add_dependency(%q<shoulda>, [">= 0"])
    s.add_dependency(%q<activerecord>, [">= 0"])
  end
end

