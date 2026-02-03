platform :ios, '16.0'

project 'Hourglass 4.xcodeproj'

use_frameworks! :linkage => :static

inhibit_all_warnings!

target 'Hourglass 4' do
  pod 'FirebaseCore'
  pod 'FirebaseAuth'
  pod 'FirebaseFirestore'
  pod 'FirebaseFunctions'
  pod 'FirebaseMessaging'
  pod 'FirebaseStorage'
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '16.0'
    end
  end

  # Fix macOS realpath incompatibility in CocoaPods scripts.
  resources_script = File.join(installer.sandbox.root, 'Target Support Files', 'Pods-Hourglass 4', 'Pods-Hourglass 4-resources.sh')
  if File.exist?(resources_script)
    script_contents = File.read(resources_script)
    fixed_contents = script_contents
      .gsub('realpath -mq "${0}"', '/usr/bin/python3 -c \'import os,sys; print(os.path.realpath(sys.argv[1]))\' "${0}"')
      .gsub('realpath -m "${0}"', '/usr/bin/python3 -c \'import os,sys; print(os.path.realpath(sys.argv[1]))\' "${0}"')
      .gsub('RESOURCES_TO_COPY=${PODS_ROOT}/resources-to-copy-${TARGETNAME}.txt', 'RESOURCES_TO_COPY="${TEMP_DIR}/resources-to-copy-${TARGETNAME}.txt"')
    if fixed_contents != script_contents
      File.write(resources_script, fixed_contents)
    end
  end

  # Disable script sandboxing so Pods scripts can write to Pods/ during build.
  installer.aggregate_targets.each do |aggregate_target|
    aggregate_target.user_project.native_targets.each do |native_target|
      native_target.build_configurations.each do |config|
        config.build_settings['ENABLE_USER_SCRIPT_SANDBOXING'] = 'NO'
      end
    end
  end
end
