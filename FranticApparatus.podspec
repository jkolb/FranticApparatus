Pod::Spec.new do |s|
  s.name         = "FranticApparatus"
  s.version      = "0.3.0"
  s.summary      = "An asynchronous task framework for iOS."
  s.homepage     = "http://franticapparatus.net"
  s.license      = 'MIT'
  s.author       = { "Justin Kolb" => "franticapparatus@gmail.com" }
  s.source       = { :git => "https://github.com/jkolb/FranticApparatus.git", :tag => "0.3.0" }
  s.platform     = :ios, '6.0'
  s.requires_arc = true
  s.source_files = 'FranticApparatus', 'FranticApparatus/Network', 'FranticApparatus/Task'
  s.ios.deployment_target = '6.0'
  s.ios.frameworks        = 'Foundation'
end
