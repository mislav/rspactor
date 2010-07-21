# -*- encoding: utf-8 -*-

Gem::Specification.new do |gem|
  gem.name    = "rspactor"
  gem.version = "0.4.0"
  
  gem.summary = "File watcher that automatically runs changed specs"
  gem.description = "RSpactor is a command line tool to automatically run your changed specs (much like autotest)."
  gem.homepage = "http://github.com/mislav/rspactor"
  gem.email = "mislav.marohnic@gmail.com"
  gem.authors = ["Mislav Marohnić", "Andreas Wolff", "Pelle Braendgaard"]
  
  gem.files = Dir['Rakefile', '{bin,lib,images,spec}/**/*', 'README*', 'LICENSE*']
  gem.has_rdoc = false
end
