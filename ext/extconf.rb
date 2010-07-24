require 'rbconfig'

# Workaround to make Rubygems believe it builds a native gem
File.open(File.expand_path('../Makefile', __FILE__), 'w') do |f|
  f.puts("install:\n\t$(exit 0)")
end

if Config::CONFIG['host_os'].to_s =~ /\b(darwin|osx)/i
  darwin_verion = `uname -r`.to_i
  sdk_verion    = { 9 => '10.5', 10 => '10.6', 11 => '10.7' }[darwin_verion]
  
  raise "Darwin #{darwin_verion} is not supported" unless sdk_verion
  
  source_file = File.expand_path("../fsevent/fsevent_watch.c", __FILE__)
  target_bin  = File.expand_path("../../bin/#{File.basename(source_file, '.c')}", __FILE__)

  old_cflags  = ENV['CFLAGS']
  
  cflags = %w[-isysroot] <<
    "/Developer/SDKs/MacOSX#{sdk_verion}.sdk" <<
    "-mmacosx-version-min=#{sdk_verion}" <<
    old_cflags
  
  ENV['CFLAGS'] = cflags.join(' ')
  
  begin
    # Compile the actual fsevent_watch binary
    system('gcc', '-framework', 'CoreServices', '-o', target_bin, source_file)
  ensure
    ENV['CFLAGS'] = old_cflags
  end
  
  raise 'Compiling "fsevent_watch" failed' unless File.executable? target_bin
end
