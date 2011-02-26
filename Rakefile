require 'rake/rdoctask'


spec = Gem::Specification.load(File.expand_path("website_screenshot.gemspec", File.dirname(__FILE__)))

# Create the documentation.
Rake::RDocTask.new do |rdoc|
  rdoc.rdoc_files.include "README.rdoc", "lib/**/*.rb"
  rdoc.options = spec.rdoc_options
end

desc "Push new release to rubyforge and git tag"
task :push do
  sh "git push"
  puts "Tagging version #{spec.version} .."
  sh "git tag v#{spec.version}"
  sh "git push --tag"
  puts "Building and pushing gem .."
  sh "gem build #{spec.name}.gemspec"
  sh "gem push #{spec.name}-#{spec.version}.gem"
end

desc "Install #{spec.name} locally"
task :install do
  sh "gem build #{spec.name}.gemspec"
  sh "gem install #{spec.name}-#{spec.version}.gem"
end
