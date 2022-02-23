task :doit do
  puts "Hello world"
end

task :dont do 
  puts "Not doing it"
  Rake::Task[:doit].clear
end

file "main.o" => "main.c" do 
  sh 'zig cc -c -o main.o main.c'
end

file 'hello' => 'hello.o' do
  sh 'cc -o hello hello.o'
end

namespace :build do 
  desc "Build the program"

  task :main => [:pkg1, :pkg2] do
    puts "got pkg 1 and 2"
  end

  task :ext => :build do
    puts "ext to build"
  end
end

rule '.o' => '.c' do |t|
  sh "zig cc #{t.source} -c -o #{t.name}"
end
