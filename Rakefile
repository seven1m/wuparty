require 'hanna/rdoctask'
Rake::RDocTask.new(:rdoc) do |rdoc|
  rdoc.rdoc_files.include('README.rdoc', 'lib/wufoo_party.rb')
  rdoc.main = "README.rdoc"
  rdoc.title = "WufooParty"
  rdoc.rdoc_dir = 'doc'
  rdoc.options << '--webcvs=http://github.com/seven1m/wufoo_party/tree/master/%s'
end


require 'grancher/task'
Grancher::Task.new do |g|
  g.branch = 'gh-pages'
  g.push_to = 'origin'
  g.message = 'Updated RDoc.'
  g.directory 'doc'
end
