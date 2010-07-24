require 'osx/foundation'
OSX.require_framework '/System/Library/Frameworks/CoreServices.framework/Frameworks/CarbonCore.framework'

module RSpactor
  # based on http://rails.aizatto.com/2007/11/28/taming-the-autotest-beast-with-fsevents/
  class Listener
    attr_reader :last_check, :callback, :options, :dirs, :force_changed

    # Options examples:
    #   {:extensions => ['rb', 'haml'], :relative_paths => true, :latency => .1}
    def initialize(options = {})
      @options = options
      timestamp_checked
      @force_changed = []
      
      @callback = lambda do |stream, ctx, num_events, paths, marks, event_ids|
        changed_files = extract_changed_files_from_paths(split_paths(paths, num_events))
        timestamp_checked
        changed_files = relativize_path_names(changed_files) if options[:relative_paths]
        yield changed_files unless changed_files.empty?
      end
    end
    
    def relativize_path_names(files)
      for file in files
        if dir = @dirs.find { |p| file.index(p) == 0 }
          file.sub!(dir + '/', '')
        end
      end
    end

    def start(directories)
      @dirs = Array(directories)
      since = OSX::KFSEventStreamEventIdSinceNow
      
      @stream = OSX::FSEventStreamCreate(OSX::KCFAllocatorDefault, callback, nil, @dirs, since, options[:latency] || 0.0, 0)
      unless @stream
        $stderr.puts "Failed to create stream"
        exit(1)
      end

      OSX::FSEventStreamScheduleWithRunLoop(@stream, OSX.CFRunLoopGetCurrent, OSX::KCFRunLoopDefaultMode)
      unless OSX::FSEventStreamStart(@stream)
        $stderr.puts "Failed to start stream"
        exit(1)
      end
      
      return self
    end

    def enter_run_loop
      begin
        OSX::CFRunLoopRun()
      rescue Interrupt
        stop
      end
    end
    
    def stop
      OSX::FSEventStreamStop(@stream)
      OSX::FSEventStreamInvalidate(@stream)
      OSX::FSEventStreamRelease(@stream)
    end

    def timestamp_checked
      @last_check = Time.now
    end

    def split_paths(paths, num_events)
      paths.regard_as('*')
      rpaths = []
      num_events.times { |i| rpaths << paths[i] }
      rpaths
    end

    def extract_changed_files_from_paths(paths)
      changed_files = []
      paths.each do |path|
        next if ignore_path?(path)
        Dir.glob(path + "*").each do |file|
          next if ignore_file?(file)
          changed_files << file if file_changed?(file)
        end
      end
      changed_files
    end

    def file_changed?(file)
      return true if force_changed.delete(file)
      file_mtime = File.stat(file).mtime
      file_mtime > last_check
    rescue Errno::ENOENT
      false
    end

    def ignore_path?(path)
      path =~ /(?:^|\/)\.(git|svn)/
    end

    def ignore_file?(file)
      File.basename(file).index('.') == 0 or not valid_extension?(file)
    end

    def file_extension(file)
      file =~ /\.(\w+)$/ and $1
    end

    def valid_extension?(file)
      options[:extensions].nil? or options[:extensions].include?(file_extension(file))
    end
  end
end
