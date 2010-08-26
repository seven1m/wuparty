task :doc do
  puts `hanna -o doc --inline-source -T hanna -U -t WufooParty --main=README.rdoc README.rdoc lib/wufoo_party.rb`
end

require 'grancher/task'
Grancher::Task.new do |g|
  g.branch = 'gh-pages'
  g.push_to = 'origin'
  g.message = 'Updated RDoc.'
  g.directory 'doc'
end
