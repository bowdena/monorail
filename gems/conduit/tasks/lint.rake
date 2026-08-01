namespace :lint do
  desc "Autocorrect Ruby offenses"
  task :autocorrect do
    sh "bundle exec rubocop --autocorrect"
  end
end

desc "Run all lint checks (rubocop)"
task :lint do
  sh "bundle exec rubocop"
end
