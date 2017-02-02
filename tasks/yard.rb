# frozen_string_literal: true
begin
  require 'yard'

  YARD::Rake::YardocTask.new do |t|
    t.files = ['./api/**/.rb',
               './lib/**/*.rb']
  end

  namespace :yard do
    desc 'renders dependency graph'
    task graph: :yard do
      puts "\n\ngenerating graph...\n"
      yard_cmd = 'yard graph --protected --private --full --dependencies'

      # TODO: yard graph renders identifiers with ".self", which dot flags as
      #   syntax errors. not sure what to do about them or if removing them
      #   actually breaks the manipulated nodes, but it seems to work somehow.
      sed_cmd = 'sed s/\.self//g'

      dot_cmd = 'dot -Tjpg -o ./doc/yardoc/yard_graph.jpg'

      `#{yard_cmd} | #{sed_cmd} | #{dot_cmd}`
      puts 'done.'
    end
  end

rescue LoadError
  task :yard do
    abort 'YARD is not available. Run "gem install yard" if you want to use it.'
  end
end
