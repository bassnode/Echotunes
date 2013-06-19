task :default => :start

desc "Opens the app"
task :start do
  pid = fork{ `sleep 2; open "http://localhost:4567"` }
  sh 'ruby app.rb'
end
