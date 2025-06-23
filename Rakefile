task :compile_extension do
  Dir.chdir("ext/zig-base64") do
    ruby "extconf.rb"
    sh "make"
  end
end