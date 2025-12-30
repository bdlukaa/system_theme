#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint system_theme.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'system_theme'
  s.version          = '3.2.0'
  s.summary          = 'A Flutter Plugin to retrieve the system theme.'
  s.description      = <<-DESC
A plugin to get the current system theme info. Supports Android, Web, Windows, Linux and macOS
                       DESC
  s.homepage         = 'https://github.com/bdlukaa/system_theme'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Bruno D Luka' => 'email@example.com' }

  s.source           = { :path => '.' }
  s.source_files     = 'system_theme/Sources/system_theme/**/*.swift'
  s.dependency 'FlutterMacOS'

  s.platform = :osx, '10.11'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
  s.swift_version = '5.0'
end
