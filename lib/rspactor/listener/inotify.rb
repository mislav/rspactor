require 'rb-inotify'

module RSpactor
  class Listener
    def start(directories)
      @dirs = Array(directories)
      @notifier = INotify::Notifier.new
      watch_proc = lambda { |event| fire_callback(event.absolute_name) }
      @dirs.each do |dir|
        notifier.watch(dir, :modify, :moved_to, :create, :recursive, &watch_proc)
      end
      return self
    end
    
    def run
      raise ArgumentError, "no callback given" unless @callback
      @notifier.run
    rescue Interrupt
      stop
    end
    
    def stop
      @notifier.stop if @notifier
    end
  end
end