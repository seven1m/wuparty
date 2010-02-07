Gem::Specification.new do |s|
  s.name = "wufoo_party"
  s.version = "0.1.0"
  s.author = "Tim Morgan"
  s.email = "tim@timmorgan.org"
  s.homepage = "http://seven1m.github.com/wufoo_party"
  s.summary = "Lightweight wrapper for Wufoo API over HTTP using HTTParty"
  s.files = %w(README.rdoc lib/wufoo_party.rb test/wufoo_party_test.rb)
  s.require_path = "lib"
  s.has_rdoc = true
  s.add_dependency("httparty")
end
