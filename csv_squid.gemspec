Gem::Specification.new do |spec|
  spec.name = "csv_squid"
  spec.version = "0.0.1"
  spec.date = "2010-8-10"
  spec.authors = ["dbiser"]
  spec.email = "dbiser@optoro.com"
  spec.summary = "csv_squid creates a Comma Separated Value (csv) string from the attributes field an ActiveRecord object or array of ActiveRecord objects.  Optionally the user may pull in any number of associated ActiveRecord objects whos attributes are also to be appened to the csv table."
  spec.homepage = ""
  spec.description = "csv_squid creates a Comma Separated Value (csv) string from the attributes field an ActiveRecord object or array of ActiveRecord objects.  Optionally the user may pull in any number of associated ActiveRecord objects whos attributes are also to be appened to the csv table."
  spec.add_dependency('activerecord','>= 2.3.8')
  spec.add_dependency('fastercsv', '>= 1.5.3')
  spec.files = ["README", "Changelog", "LICENSE", "demo.rb", "lib/to_csv.rb", "lib/tree_node.rb"]
end
