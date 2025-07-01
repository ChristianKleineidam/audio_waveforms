Pod::Spec.new do |s|
  s.name             = 'audio_waveforms'
  s.version          = '0.0.1'
  s.summary          = 'Desktop implementation stub.'
  s.description      = 'Desktop implementation for audio_waveforms. Currently provides stub methods.'
  s.homepage         = 'https://github.com/SimformSolutionsPvtLtd/audio_waveforms'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Simform' => 'info@simform.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'FlutterMacOS'
  s.platform = :osx, '10.11'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
  s.swift_version = '5.0'
end
