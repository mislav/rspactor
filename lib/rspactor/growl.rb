module RSpactor
  module Growl
    extend self
    
    IMAGE_PATH = File.expand_path File.dirname(__FILE__) + "/../../images/%s.png"
    
    def notify(title, msg, img, pri = 0)
      system("growlnotify -w -n rspactor --image #{img} -p #{pri} -m #{msg.inspect} #{title} &") 
    end
    
    # failed | pending | success
    def image_path(icon)
      IMAGE_PATH % icon
    end
  end
end