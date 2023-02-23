Pod::Spec.new do |s|
  s.name         = "YCLog"
  s.version      = "0.0.1"
  s.summary      = "iOS console log"
  s.homepage     = "https://github.com/onezens/YCLog"
  s.license      = "MIT"
  s.author       = { "onezens" => "mail@onezen.cc" }
  s.platform     = :ios, "8.0"
  s.source       = { :git => "https://github.com/onezens/YCLog.git", :tag => "#{s.version}" }

  s.source_files  = "YCLog/Class/*.{h,m}"
  s.public_header_files = "YCLog/Class/*.h"
  s.dependency 'CocoaAsyncSocket'
  s.requires_arc = true
  s.frameworks = 'CFNetwork'

end
