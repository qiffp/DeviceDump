def install_dir
  "/usr/local/bin"
end

desc "Create a Release build"
task :build => :clean do
  sh "xcodebuild clean build -project DeviceDump.xcodeproj -configuration Release SYMROOT=build"
end

desc "Install a Release Build"
task :install => :build do
  cp "build/Release/devicedump", install_dir
end

desc "Remove DeviceDump from the system"
task :uninstall => :clean do
  rm "#{install_dir}/devicedump" if File.exist? "#{install_dir}/devicedump"
end

desc "Delete the build directory"
task :clean do
  rm_rf "build" if File.exist? "build"
end
