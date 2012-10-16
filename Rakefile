require 'hanna/rdoctask'
Rake::RDocTask.new(:rdoc) do |rdoc|
  rdoc.rdoc_files.include('README.rdoc', 'lib/wuparty.rb')
  rdoc.main = "README.rdoc"
  rdoc.title = "WuParty"
  rdoc.rdoc_dir = 'doc'
  rdoc.options << '--webcvs=http://github.com/seven1m/wuparty/tree/master/%s'
end


require 'grancher/task'
Grancher::Task.new do |g|
  g.branch = 'gh-pages'
  g.push_to = 'origin'
  g.message = 'Updated RDoc.'
  g.directory 'doc'
end


task :test do
  require('./test/wuparty_test')
end
