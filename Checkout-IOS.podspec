Pod::Spec.new do |s|
  s.name             = 'Checkout-IOS'
  s.version          = '1.0.2'
  s.summary          = 'From the shelf checkout processing library provided by Tap Payments'
  s.homepage         = 'https://github.com/Tap-Payments/Checkout-IOS'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'o.rabie' => 'o.rabie@tap.company', 'h.sheshtawy' => 'h.sheshtawy@tap.company', 'm.allam' => 'm.allam@tap.company' }
  s.source           = { :git => 'https://github.com/Tap-Payments/Checkout-IOS.git', :tag => s.version.to_s }
  s.ios.deployment_target = '13.0'
  s.swift_version = '5.0'
  s.source_files = 'Sources/Checkout-IOS/Logic/**/*.swift'
  s.resource_bundles = {
    'Checkout-iOS_Checkout-iOS' => ['Sources/Checkout-IOS/Resources/**/*.{xcassets,json,xib,pdf,png,gif,storyboard,xcdatamodeld,lproj}']
  }  
  s.dependency'SwiftEntryKit'
  s.dependency'SwiftyRSA'
  s.dependency'SnapKit'
  s.dependency'SharedDataModels-iOS'
  s.dependency'TapCardScannerWebWrapper-iOS'
  s.dependency'TapFontKit-iOS'
  
  
end

