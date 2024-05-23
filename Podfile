# Uncomment the next line to define a global platform for your project
target 'YCLogDemo' do
  # Pods for YCLog
  pod 'YCLog', :path => '.'
end

target 'YCLogConsole' do
  # Pods for YCLogConsole
  pod 'CocoaAsyncSocket'
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings["IPHONEOS_DEPLOYMENT_TARGET"] = "11.0"
    end
  end
end
