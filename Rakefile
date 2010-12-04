require 'rubygems'
require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require 'rake'

require 'jeweler'
Jeweler::Tasks.new do |gem|
  gem.name = "nugramserver-ruby"
  gem.homepage = "http://github.com/jsgoecke/nugramserver-ruby"
  gem.license = "Apache 2.0"
  gem.summary = "NuGram Hosted Server client APIs"
  gem.description = ""
  gem.email = "nugram-support@nuecho.com"
  gem.authors = ["NuEcho"]
  gem.add_runtime_dependency 'json'
  gem.add_development_dependency 'rspec'
  gem.files = Dir.glob('lib/**/*.rb')
end
Jeweler::RubygemsDotOrgTasks.new

require 'rspec/core'
require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.pattern = FileList['spec/**/*_spec.rb']
end

RSpec::Core::RakeTask.new(:rcov) do |spec|
  spec.pattern = 'spec/**/*_spec.rb'
  spec.rcov = true
end

task :default => :spec

require 'yard'
YARD::Rake::YardocTask.new
