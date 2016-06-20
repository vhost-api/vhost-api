begin
  require 'rubocop/rake_task'
  require 'benchmark'

  RuboCop::RakeTask.new(:rubocop) do |t|
    t.options = ['-D', '-S', '-E']
  end
end
