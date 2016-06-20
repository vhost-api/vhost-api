begin
  require 'haml_lint/rake_task'
  require 'benchmark'

  HamlLint::RakeTask.new do |t|
    t.files = ['views/*.haml']
  end
end
