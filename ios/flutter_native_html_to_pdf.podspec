Pod::Spec.new do |s|
  s.name             = 'flutter_native_html_to_pdf'
  s.version          = '3.0.0'
  s.summary          = 'A Flutter plugin that uses native WKWebView to render HTML and convert it to a PDF.'
  s.description      = <<-DESC
A Flutter plugin that uses WKWebView on iOS to render HTML content and generate high-quality
PDF files or PDF bytes without any third-party dependencies.
                       DESC
  s.homepage         = 'https://github.com/Pisey-Nguon/flutter_native_html_to_pdf'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Pisey Nguon' => 'author@example.com' }
  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform         = :ios, '12.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386'
  }
  s.swift_version = '5.0'
end
