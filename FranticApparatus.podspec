Pod::Spec.new do |s|
  s.name             = "FranticApparatus"
  s.version          = "2.0.0"
  s.summary          = "Makes asynchronous Objective-C easy!"
  s.homepage         = "http://franticapparatus.net"
  s.license          = 'MIT'
  s.author           = { "Justin Kolb" => "justin.kolb@franticapparatus.net" }
  s.source           = { :git => "https://github.com/jkolb/FranticApparatus.git", :tag => s.version.to_s }
  s.requires_arc = true
  s.ios.deployment_target = '6.0'
  s.osx.deployment_target = '10.8'
  s.source_files = 'FranticApparatus/**/*.m'
  s.public_header_files = 'FranticApparatus/**/*.h'
  s.frameworks = 'Foundation'
end
