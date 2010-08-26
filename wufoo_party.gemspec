Gem::Specification.new do |s|
  s.name         = "wufoo_party"
  s.version      = "1.0.0"
  s.author       = "Tim Morgan"
  s.email        = "tim@timmorgan.org"
  s.homepage     = "http://seven1m.github.com/wufoo_party"
  s.summary      = "Ruby wrapper for Wufoo's REST API v3."
  s.files        = %w(README.rdoc lib/wufoo_party.rb test/wufoo_party_test.rb)
  s.require_path = "lib"
  s.has_rdoc     = true
  s.add_dependency("httparty",       ">= 0.6.1")
  s.add_dependency("multipart-post", ">= 1.0.1")
  s.add_dependency("mime-types",     ">= 1.16" )
end
