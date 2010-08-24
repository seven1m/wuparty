Gem::Specification.new do |s|
  s.name = "wufoo_party"
  s.version = "0.9.0"
  s.author = "Tim Morgan"
  s.email = "tim@timmorgan.org"
  s.homepage = "http://seven1m.github.com/wufoo_party"
  s.summary = "Lightweight wrapper for Wufoo API over HTTP using HTTParty"
  s.description = "This is a very simple API wrapper that utilizes HTTParty -- a wonderful gem for consuming REST APIs.

This lib supports Wufoo's api version 3.0.

If you need to use version 2 of Wufoo's api, please use the 0.1.x release of WufooParty."
  s.files = %w(README.rdoc lib/wufoo_party.rb test/wufoo_party_test.rb)
  s.require_path = "lib"
  s.has_rdoc = true
  s.add_dependency("httparty")
  s.add_dependency("multipart-post")
  s.add_dependency("mime-types")
end
