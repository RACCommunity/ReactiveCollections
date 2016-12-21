Pod::Spec.new do |s|
  s.name         = "ReactiveCollections"
  s.version      = "1.0.0-alpha.0"
  s.summary      = ""
  s.description  = <<-DESC
Reactive collections for Swift using ReactiveSwift
                   DESC
  s.homepage     = "https://github.com/RACCommunity/ReactiveCollections/"
  s.license      = { :type => "MIT", :file => "LICENSE.md" }
  s.author       = "RACCommunity"
  
  s.ios.deployment_target = "8.0"
  s.osx.deployment_target = "10.9"
  s.watchos.deployment_target = "2.0"
  s.tvos.deployment_target = "9.0"
  s.source       = { :git => "https://github.com/RACCommunity/ReactiveCollections.git", :branch => "master" }
  # Directory glob for all Swift files
  s.source_files  = "Sources/*.{swift}"
  s.dependency 'ReactiveSwift', '~> 1.0'
end
