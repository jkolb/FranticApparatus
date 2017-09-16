Pod::Spec.new do |s|
  s.name             = 'FranticApparatus'
  s.version          = '7.0.0'
  s.summary          = 'Promises/A+ for Swift'
  s.description      = <<-DESC
Type safe, memory safe promises for Swift. Cancellation supported.
                       DESC
  s.homepage         = 'https://github.com/jkolb/FranticApparatus'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'jkolb' => 'franticapparatus@gmail.com' }
  s.source           = { :git => 'https://github.com/jkolb/FranticApparatus.git', :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/nabobnick'
  s.ios.deployment_target = '8.0'
  s.osx.deployment_target = '10.10'
  s.source_files     = 'Sources/FranticApparatus/*.swift'
end
