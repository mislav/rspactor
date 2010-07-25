module RSpactor
  class Listener
    attr_reader :last_check, :callback, :options, :dirs, :force_changed

    # Options examples:
    #   {:extensions => ['rb', 'haml'], :relative_paths => true, :latency => .1}
    #
    # TODO: pass latency setting down to fsevent_watch
    def initialize(options = {}, &callback)
      @options = options
      @force_changed = []
      @callback = callback
      @pipe = nil
      timestamp_checked
    end

    def start(directories)
      @dirs = Array(directories)
      watcher = File.expand_path('../../../bin/fsevent_watch', __FILE__)
      # FIXME: support directories with spaces in them
      @pipe = IO.popen("#{watcher} #{@dirs.join(' ')}", 'r')
      return self
    end
    
    def run
      raise ArgumentError, "no callback given" unless @callback
      until @pipe.eof?
        if line = @pipe.readline
          modified_dirs = line.chomp.split("\0")
          fire_callback detect_changed_files(modified_dirs)
        end
      end
    rescue Interrupt
      stop
    end
    
    def stop
      Process.kill("HUP", @pipe.pid) if @pipe
    end

    def ignore_path?(path)
      path =~ %r{/\.(?:git|svn)(?:/|$)}
    end

    def ignore_file?(file)
      File.basename(file).index('.') == 0 or not valid_extension?(file)
    end

    def valid_extension?(file)
      options[:extensions].nil? or
        options[:extensions].include?(File.extname(file).sub('.', ''))
    end
    
    def glob_pattern
      if options[:extensions]
        "*.{%s}" % options[:extensions].join(',')
      else
        "*"
      end
    end

    protected

    def timestamp_checked
      @last_check = Time.now
    end
    
    def fire_callback(files)
      relativize_path_names(files) if options[:relative_paths]
      timestamp_checked
      @callback.call(files) unless files.empty?
    end

    def detect_changed_files(paths)
      paths.reject {|p| ignore_path?(p) }.inject([]) do |changed, path|
        candidates = Dir.glob(File.join(path, glob_pattern))
        # TODO: this doesn't use `ignore_file?`
        changed.concat candidates.select {|f| file_changed?(f) }
      end
    end

    def file_changed?(file)
      return true if force_changed.delete(file)
      file_mtime = File.stat(file).mtime
      file_mtime > last_check
    rescue Errno::ENOENT
      false
    end

    def relativize_path_names(files)
      for file in files
        if dir = @dirs.find { |p| file.index(p) == 0 }
          file.sub!(dir + '/', '')
        end
      end
    end
  end
end
