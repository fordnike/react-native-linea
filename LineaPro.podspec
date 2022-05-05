
require 'json'

package = JSON.parse(File.read(File.join(__dir__, 'package.json')))

Pod::Spec.new do |s|
s.name                 = 'LineaPro'
s.version              = package['version']
s.summary              = package['description']
s.license              = package['license']
s.homepage             = 'https://github.com/fordnike/react-native-linea'
s.authors              = package['author']
s.source               = { :git => 'https://github.com/fordnike/react-native-linea.git', :tag => s.version }
s.source_files         = '*.{h,m}','react-native-linea/*.{h,m}'
s.requires_arc         = true
s.platforms            = { :ios => "9.0" }
s.vendored_libraries   = 'libdtdev.a'
s.frameworks           = 'ExternalAccessory', 'CoreLocation','infineaSDK'
s.ios.vendored_frameworks = 'Frameworks/infineaSDK.framework'
s.dependency           'React'
end
