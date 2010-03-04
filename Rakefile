require 'spec/rake/spectask'

desc 'Default: run specs'
task :default => :spec
Spec::Rake::SpecTask.new do |t|
  t.spec_files = FileList["spec/**/*_spec.rb"]
end

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gemspec|
    gemspec.name = "acts_as_muschable"
    gemspec.summary = "Easy peasy model sharding"
    gemspec.description = "Do not use me unless you are not you but somebody else."
    gemspec.email = "jannis@moviepilot.de"
    gemspec.homepage = "http://github.com/moviepilot/acts_as_muschable"
    gemspec.authors = ["Moviepilot"]
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler not available. Install it with: gem install jeweler"
end