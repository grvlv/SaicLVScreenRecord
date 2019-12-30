Pod::Spec.new do |spec|
  spec.name         = "SaicLVScreenRecord"
  spec.version      = "1.0.0"
  spec.summary      = "录屏流处理合成文件和上传"
  spec.homepage     = "https://github.com/grvlv/SaicLVScreenRecord"
  spec.license      = "Copyright (c) 2019 GRV"
  spec.author       = { "grvlv" => "grv_lv@126.com" }
  spec.source       = { :git => "https://github.com/grvlv/SaicLVScreenRecord.git", :tag => "#{spec.version}" }
  spec.source_files  = "SaicLVScreenRecord/*"
  spec.requires_arc = true
  spec.ios.deployment_target = '12.0'
  spec.dependency 'AFNetworking'
  spec.frameworks = 'ReplayKit','AVFoundation','Photos'
end
