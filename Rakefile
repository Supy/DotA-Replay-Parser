require 'bundler'
Bundler::GemHelper.install_tasks

task :test do
  require 'rake/runtest'
  $LOAD_PATH.unshift File.expand_path(File.dirname(__FILE__))
  Rake.run_tests
end
