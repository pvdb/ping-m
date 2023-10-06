# frozen_string_literal: true

# rubocop:disable Style/SymbolArray
# rubocop:disable Style/HashSyntax
# rubocop:disable Rake/Desc

require 'bundler/gem_tasks'

task :validate_gemspec do
  Bundler.load_gemspec('ping-m.gemspec').validate
end

task :version => :validate_gemspec do
  puts Ping::Monitor::VERSION
end

require 'rubocop/rake_task'

RuboCop::RakeTask.new(:rubocop)

require 'rake/testtask'

Rake::TestTask.new(:test) do |t|
  t.libs << 'test'
  t.libs << 'lib'
  t.test_files = FileList['test/**/*_test.rb']
end

task :coverage do
  ENV['COVERAGE'] = 'simplecov'
  Rake::Task['test'].invoke
  ENV.delete('COVERAGE')
end

task :default => [:rubocop, :test]

task :documentation

Rake::Task['build'].enhance([:default, :documentation])

# rubocop:enable Rake/Desc
# rubocop:enable Style/HashSyntax
# rubocop:enable Style/SymbolArray
