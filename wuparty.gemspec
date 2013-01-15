Gem::Specification.new do |s|
  s.name         = "wuparty"
  s.version      = "1.2.2"
  s.author       = "Tim Morgan"
  s.email        = "tim@timmorgan.org"
  s.homepage     = "http://seven1m.github.com/wuparty"
  s.summary      = "Ruby wrapper for Wufoo's REST API v3."
  s.files        = %w(README.rdoc lib/wuparty.rb test/wuparty_test.rb)
  s.require_path = "lib"
  s.has_rdoc     = true
  s.add_dependency("httparty",       ">= 0.6.1")
  s.add_dependency("multipart-post", ">= 1.0.1")
  s.add_dependency("mime-types",     ">= 1.16" )
end
