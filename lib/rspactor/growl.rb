module RSpactor
  module Growl
    extend self
    
    ICON_PATTERN = File.expand_path('../images', __FILE__) + '/%s.png'
    
    def notify(title, message, img = nil, priority = 0)
      img = icon_path(img) if Symbol === img
      
      args = %w[--name rspactor]
      args << '--image' << img if img
      args << '--priority' << priority
      args << '--message' << message
      args << title
      
      system('growlnotify', *args) 
    end
    
    # failed | pending | success
    def icon_path(name)
      ICON_PATTERN % name
    end
  end
end