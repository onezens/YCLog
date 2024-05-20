Pod::Spec.new do |s|
  s.name         = "YCLog"
  s.version      = "1.0.2"
  s.summary      = "iOS console log"
  s.homepage     = "https://github.com/onezens/YCLog"
  s.license      = "MIT"
  s.author       = { "onezens" => "mail@onezen.cc" }
  s.ios.deployment_target = '9.0'
  s.osx.deployment_target = '13.0'
  s.source       = { :git => "https://github.com/onezens/YCLog.git", :tag => "#{s.version}" }

  s.source_files  = "YCLog/Class/*.{h,m}"
  s.public_header_files = "YCLog/Class/*.h"
  s.dependency 'CocoaAsyncSocket'
  s.requires_arc = true
  s.frameworks = 'CFNetwork'

end
