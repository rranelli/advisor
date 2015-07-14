require 'bundler/gem_tasks'

task deploy: [:build] do
  # sh "git tag #{Advisor::VERSION}"
  sh 'bundle install'
  sh 'gem push pkg/*.gem'
  sh 'rm -rf pkg/*.gem'
  sh 'git add Gemfile.lock && git commit --amend --no-edit'
  sh 'git push && git push --tags'
end
