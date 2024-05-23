#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint flutter_silero_vad.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'flutter_silero_vad'
  s.version          = '0.0.1'
  s.summary          = 'A new Flutter plugin project.'
  s.description      = <<-DESC
A new Flutter plugin project.
                       DESC
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.dependency 'onnxruntime-objc', '1.15.0'
  s.platform = :ios, '11.0'

  s.swift_version = '5.0'
  s.static_framework = true
end
