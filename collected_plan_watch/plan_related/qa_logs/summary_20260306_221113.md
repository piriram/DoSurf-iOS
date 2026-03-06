# Release Preflight Summary

- timestamp: 20260306_221113
- root: /Users/piri/shared/active/DoSurf-iOS-iosclaw
- xcode: Xcode 26.2;Build version 17C52;

## scheme_list

- command: `xcodebuild -list -project DoSurfApp.xcodeproj`
- exit_code: 0
- first_error: none
- optional: false
- log_file: /Users/piri/shared/active/DoSurf-iOS-iosclaw/collected_plan_watch/plan_related/qa_logs/scheme_list_20260306_221113.log

### tail
```text
        DoSurfApp
        DoSurfWatch Watch App
        DoSurfWatch Watch App WatchKitExtension
        DoSurfWidgetExtensionExtension

    Build Configurations:
        Debug
        Release

    If no build configuration is specified and -scheme is not passed then "Release" is used.

    Schemes:
        DoSurfApp
        DoSurfWatch Watch App
        DoSurfWatch Watch App
        DoSurfWatch Watch App (Complication)
        DoSurfWatch Watch App (Notification)
        DoSurfWatch Watch App (Notification)
        DoSurfWidgetExtensionExtension

```

## show_destinations

- command: `xcodebuild -project DoSurfApp.xcodeproj -scheme DoSurfApp -showdestinations`
- exit_code: 0
- first_error: none
- optional: false
- log_file: /Users/piri/shared/active/DoSurf-iOS-iosclaw/collected_plan_watch/plan_related/qa_logs/show_destinations_20260306_221113.log

### tail
```text
  RxSwift: https://github.com/ReactiveX/RxSwift.git @ 6.9.0
  leveldb: https://github.com/firebase/leveldb.git @ 1.22.5
  IQKeyboardToolbarManager: https://github.com/hackiftekhar/IQKeyboardToolbarManager.git @ 1.1.4
  IQKeyboardManagerSwift: https://github.com/hackiftekhar/IQKeyboardManager.git @ 8.0.1
  Firebase: https://github.com/firebase/firebase-ios-sdk @ 12.3.0
  GTMSessionFetcher: https://github.com/google/gtm-session-fetcher.git @ 5.0.0



	Available destinations for the "DoSurfApp" scheme:
		{ platform:iOS, arch:arm64, id:00008101-0001253A26F9001E, name:iPhone }
		{ platform:iOS, id:dvtdevice-DVTiPhonePlaceholder-iphoneos:placeholder, name:Any iOS Device }
		{ platform:iOS Simulator, id:dvtdevice-DVTiOSDeviceSimulatorPlaceholder-iphonesimulator:placeholder, name:Any iOS Simulator Device }
		{ platform:iOS Simulator, arch:arm64, id:FE0FFEE7-7731-4D1A-AE03-57BBB2EFF6A1, OS:18.6, name:16프로 }
		{ platform:iOS Simulator, arch:arm64, id:B6E2C4EE-E59B-4073-8B79-5F885F017559, OS:18.6, name:iPad Air 11-inch (M3) }
		{ platform:iOS Simulator, arch:arm64, id:8EC10653-BBE6-48F9-8B75-B522941C8B2E, OS:26.2, name:iPad Air 11-inch (M3) }
		{ platform:iOS Simulator, arch:arm64, id:26F40312-43D2-4983-B468-C20B745D6DE3, OS:18.6, name:iPad mini 5 (18.6 test) }
		{ platform:iOS Simulator, arch:arm64, id:944F046A-1212-4628-88D5-293858441A7C, OS:18.6, name:iPad mini 6 (18.6 test) }
		{ platform:iOS Simulator, arch:arm64, id:0891DDD8-CD83-4ACB-A696-4755AE6D0720, OS:18.6, name:iPhone 16 }
		{ platform:iOS Simulator, arch:arm64, id:F3AAAE05-3ABD-4CD9-BB24-016E094FDC6D, OS:18.6, name:iPhone SE (3rd generation) - iOS 18.6 }
```

## ios_build

- command: `xcodebuild -project DoSurfApp.xcodeproj -scheme DoSurfApp -configuration Debug -destination generic/platform=iOS Simulator build`
- exit_code: 0
- first_error: none
- optional: false
- log_file: /Users/piri/shared/active/DoSurf-iOS-iosclaw/collected_plan_watch/plan_related/qa_logs/ios_build_20260306_221113.log

### tail
```text
    builtin-infoPlistUtility /Users/piri/Library/Developer/Xcode/DerivedData/DoSurfApp-gsfzlkocnokhwogeccamufjbufgl/Build/Intermediates.noindex/Firebase.build/Debug-iphonesimulator/Firebase_FirebaseCoreExtension.build/empty-Firebase_FirebaseCoreExtension.plist -producttype com.apple.product-type.bundle -expandbuildsettings -format binary -platform iphonesimulator -o /Users/piri/Library/Developer/Xcode/DerivedData/DoSurfApp-gsfzlkocnokhwogeccamufjbufgl/Build/Products/Debug-iphonesimulator/Firebase_FirebaseCoreExtension.bundle/Info.plist

ProcessInfoPlistFile /Users/piri/Library/Developer/Xcode/DerivedData/DoSurfApp-gsfzlkocnokhwogeccamufjbufgl/Build/Products/Debug-iphonesimulator/Firebase_FirebaseCore.bundle/Info.plist /Users/piri/Library/Developer/Xcode/DerivedData/DoSurfApp-gsfzlkocnokhwogeccamufjbufgl/Build/Intermediates.noindex/Firebase.build/Debug-iphonesimulator/Firebase_FirebaseCore.build/empty-Firebase_FirebaseCore.plist (in target 'Firebase_FirebaseCore' from project 'Firebase')
    cd /Users/piri/Library/Developer/Xcode/DerivedData/DoSurfApp-gsfzlkocnokhwogeccamufjbufgl/SourcePackages/checkouts/firebase-ios-sdk
    builtin-infoPlistUtility /Users/piri/Library/Developer/Xcode/DerivedData/DoSurfApp-gsfzlkocnokhwogeccamufjbufgl/Build/Intermediates.noindex/Firebase.build/Debug-iphonesimulator/Firebase_FirebaseCore.build/empty-Firebase_FirebaseCore.plist -producttype com.apple.product-type.bundle -expandbuildsettings -format binary -platform iphonesimulator -o /Users/piri/Library/Developer/Xcode/DerivedData/DoSurfApp-gsfzlkocnokhwogeccamufjbufgl/Build/Products/Debug-iphonesimulator/Firebase_FirebaseCore.bundle/Info.plist

ProcessInfoPlistFile /Users/piri/Library/Developer/Xcode/DerivedData/DoSurfApp-gsfzlkocnokhwogeccamufjbufgl/Build/Products/Debug-watchsimulator/DoSurfWatch\ Watch\ App.app/Info.plist /Users/piri/shared/active/DoSurf-iOS-iosclaw/DoSurfWatch-Watch-App-Info.plist (in target 'DoSurfWatch Watch App' from project 'DoSurfApp')
    cd /Users/piri/shared/active/DoSurf-iOS-iosclaw
    builtin-infoPlistUtility /Users/piri/shared/active/DoSurf-iOS-iosclaw/DoSurfWatch-Watch-App-Info.plist -producttype com.apple.product-type.application.watchapp2 -genpkginfo /Users/piri/Library/Developer/Xcode/DerivedData/DoSurfApp-gsfzlkocnokhwogeccamufjbufgl/Build/Products/Debug-watchsimulator/DoSurfWatch\ Watch\ App.app/PkgInfo -expandbuildsettings -format binary -platform watchsimulator -additionalcontentfile /Users/piri/Library/Developer/Xcode/DerivedData/DoSurfApp-gsfzlkocnokhwogeccamufjbufgl/Build/Intermediates.noindex/DoSurfApp.build/Debug-watchsimulator/DoSurfWatch\ Watch\ App.build/assetcatalog_generated_info.plist -scanforprivacyfile /Users/piri/Library/Developer/Xcode/DerivedData/DoSurfApp-gsfzlkocnokhwogeccamufjbufgl/Build/Products/Debug-watchsimulator/DoSurfWatch\ Watch\ App.app/PlugIns/DoSurfWatch\ Watch\ App\ WatchKitExtension.appex -o /Users/piri/Library/Developer/Xcode/DerivedData/DoSurfApp-gsfzlkocnokhwogeccamufjbufgl/Build/Products/Debug-watchsimulator/DoSurfWatch\ Watch\ App.app/Info.plist

ProcessInfoPlistFile /Users/piri/Library/Developer/Xcode/DerivedData/DoSurfApp-gsfzlkocnokhwogeccamufjbufgl/Build/Products/Debug-iphonesimulator/DoSurfApp.app/Info.plist /Users/piri/shared/active/DoSurf-iOS-iosclaw/DoSurfApp/App/Info.plist (in target 'DoSurfApp' from project 'DoSurfApp')
    cd /Users/piri/shared/active/DoSurf-iOS-iosclaw
    builtin-infoPlistUtility /Users/piri/shared/active/DoSurf-iOS-iosclaw/DoSurfApp/App/Info.plist -producttype com.apple.product-type.application -genpkginfo /Users/piri/Library/Developer/Xcode/DerivedData/DoSurfApp-gsfzlkocnokhwogeccamufjbufgl/Build/Products/Debug-iphonesimulator/DoSurfApp.app/PkgInfo -expandbuildsettings -format binary -platform iphonesimulator -additionalcontentfile /Users/piri/Library/Developer/Xcode/DerivedData/DoSurfApp-gsfzlkocnokhwogeccamufjbufgl/Build/Intermediates.noindex/DoSurfApp.build/Debug-iphonesimulator/DoSurfApp.build/Base.lproj/LaunchScreen-SBPartialInfo.plist -additionalcontentfile /Users/piri/Library/Developer/Xcode/DerivedData/DoSurfApp-gsfzlkocnokhwogeccamufjbufgl/Build/Intermediates.noindex/DoSurfApp.build/Debug-iphonesimulator/DoSurfApp.build/assetcatalog_generated_info.plist -scanforprivacyfile /Users/piri/Library/Developer/Xcode/DerivedData/DoSurfApp-gsfzlkocnokhwogeccamufjbufgl/Build/Products/Debug-iphonesimulator/DoSurfApp.app/Firebase_FirebaseCore.bundle -scanforprivacyfile /Users/piri/Library/Developer/Xcode/DerivedData/DoSurfApp-gsfzlkocnokhwogeccamufjbufgl/Build/Products/Debug-iphonesimulator/DoSurfApp.app/Firebase_FirebaseCoreExtension.bundle -scanforprivacyfile /Users/piri/Library/Developer/Xcode/DerivedData/DoSurfApp-gsfzlkocnokhwogeccamufjbufgl/Build/Products/Debug-iphonesimulator/DoSurfApp.app/Firebase_FirebaseCoreInternal.bundle -scanforprivacyfile /Users/piri/Library/Developer/Xcode/DerivedData/DoSurfApp-gsfzlkocnokhwogeccamufjbufgl/Build/Products/Debug-iphonesimulator/DoSurfApp.app/Firebase_FirebaseFirestore.bundle -scanforprivacyfile /Users/piri/Library/Developer/Xcode/DerivedData/DoSurfApp-gsfzlkocnokhwogeccamufjbufgl/Build/Products/Debug-iphonesimulator/DoSurfApp.app/Firebase_FirebaseInstallations.bundle -scanforprivacyfile /Users/piri/Library/Developer/Xcode/DerivedData/DoSurfApp-gsfzlkocnokhwogeccamufjbufgl/Build/Products/Debug-iphonesimulator/DoSurfApp.app/Frameworks/FirebaseAnalytics.framework -scanforprivacyfile /Users/piri/Library/Developer/Xcode/DerivedData/DoSurfApp-gsfzlkocnokhwogeccamufjbufgl/Build/Products/Debug-iphonesimulator/DoSurfApp.app/Frameworks/FirebaseFirestoreInternal.framework -scanforprivacyfile /Users/piri/Library/Developer/Xcode/DerivedData/DoSurfApp-gsfzlkocnokhwogeccamufjbufgl/Build/Products/Debug-iphonesimulator/DoSurfApp.app/Frameworks/GoogleAdsOnDeviceConversion.framework -scanforprivacyfile /Users/piri/Library/Developer/Xcode/DerivedData/DoSurfApp-gsfzlkocnokhwogeccamufjbufgl/Build/Products/Debug-iphonesimulator/DoSurfApp.app/Frameworks/GoogleAppMeasurement.framework -scanforprivacyfile /Users/piri/Library/Developer/Xcode/DerivedData/DoSurfApp-gsfzlkocnokhwogeccamufjbufgl/Build/Products/Debug-iphonesimulator/DoSurfApp.app/Frameworks/GoogleAppMeasurementIdentitySupport.framework -scanforprivacyfile /Users/piri/Library/Developer/Xcode/DerivedData/DoSurfApp-gsfzlkocnokhwogeccamufjbufgl/Build/Products/Debug-iphonesimulator/DoSurfApp.app/Frameworks/absl.framework -scanforprivacyfile /Users/piri/Library/Developer/Xcode/DerivedData/DoSurfApp-gsfzlkocnokhwogeccamufjbufgl/Build/Products/Debug-iphonesimulator/DoSurfApp.app/Frameworks/grpc.framework -scanforprivacyfile /Users/piri/Library/Developer/Xcode/DerivedData/DoSurfApp-gsfzlkocnokhwogeccamufjbufgl/Build/Products/Debug-iphonesimulator/DoSurfApp.app/Frameworks/grpcpp.framework -scanforprivacyfile /Users/piri/Library/Developer/Xcode/DerivedData/DoSurfApp-gsfzlkocnokhwogeccamufjbufgl/Build/Products/Debug-iphonesimulator/DoSurfApp.app/Frameworks/openssl_grpc.framework -scanforprivacyfile /Users/piri/Library/Developer/Xcode/DerivedData/DoSurfApp-gsfzlkocnokhwogeccamufjbufgl/Build/Products/Debug-iphonesimulator/DoSurfApp.app/GoogleUtilities_GoogleUtilities-AppDelegateSwizzler.bundle -scanforprivacyfile /Users/piri/Library/Developer/Xcode/DerivedData/DoSurfApp-gsfzlkocnokhwogeccamufjbufgl/Build/Products/Debug-iphonesimulator/DoSurfApp.app/GoogleUtilities_GoogleUtilities-Environment.bundle -scanforprivacyfile /Users/piri/Library/Developer/Xcode/DerivedData/DoSurfApp-gsfzlkocnokhwogeccamufjbufgl/Build/Products/Debug-iphonesimulator/DoSurfApp.app/GoogleUtilities_GoogleUtilities-Logger.bundle -scanforprivacyfile /Users/piri/Library/Developer/Xcode/DerivedData/DoSurfApp-gsfzlkocnokhwogeccamufjbufgl/Build/Products/Debug-iphonesimulator/DoSurfApp.app/GoogleUtilities_GoogleUtilities-MethodSwizzler.bundle -scanforprivacyfile /Users/piri/Library/Developer/Xcode/DerivedData/DoSurfApp-gsfzlkocnokhwogeccamufjbufgl/Build/Products/Debug-iphonesimulator/DoSurfApp.app/GoogleUtilities_GoogleUtilities-NSData.bundle -scanforprivacyfile /Users/piri/Library/Developer/Xcode/DerivedData/DoSurfApp-gsfzlkocnokhwogeccamufjbufgl/Build/Products/Debug-iphonesimulator/DoSurfApp.app/GoogleUtilities_GoogleUtilities-Network.bundle -scanforprivacyfile /Users/piri/Library/Developer/Xcode/DerivedData/DoSurfApp-gsfzlkocnokhwogeccamufjbufgl/Build/Products/Debug-iphonesimulator/DoSurfApp.app/GoogleUtilities_GoogleUtilities-Reachability.bundle -scanforprivacyfile /Users/piri/Library/Developer/Xcode/DerivedData/DoSurfApp-gsfzlkocnokhwogeccamufjbufgl/Build/Products/Debug-iphonesimulator/DoSurfApp.app/GoogleUtilities_GoogleUtilities-UserDefaults.bundle -scanforprivacyfile /Users/piri/Library/Developer/Xcode/DerivedData/DoSurfApp-gsfzlkocnokhwogeccamufjbufgl/Build/Products/Debug-iphonesimulator/DoSurfApp.app/IQKeyboardCore_IQKeyboardCore.bundle -scanforprivacyfile /Users/piri/Library/Developer/Xcode/DerivedData/DoSurfApp-gsfzlkocnokhwogeccamufjbufgl/Build/Products/Debug-iphonesimulator/DoSurfApp.app/IQKeyboardManagerSwift_IQKeyboardManagerSwift.bundle -scanforprivacyfile /Users/piri/Library/Developer/Xcode/DerivedData/DoSurfApp-gsfzlkocnokhwogeccamufjbufgl/Build/Products/Debug-iphonesimulator/DoSurfApp.app/IQKeyboardNotification_IQKeyboardNotification.bundle -scanforprivacyfile /Users/piri/Library/Developer/Xcode/DerivedData/DoSurfApp-gsfzlkocnokhwogeccamufjbufgl/Build/Products/Debug-iphonesimulator/DoSurfApp.app/IQKeyboardReturnManager_IQKeyboardReturnManager.bundle -scanforprivacyfile /Users/piri/Library/Developer/Xcode/DerivedData/DoSurfApp-gsfzlkocnokhwogeccamufjbufgl/Build/Products/Debug-iphonesimulator/DoSurfApp.app/IQKeyboardToolbarManager_IQKeyboardToolbarManager.bundle -scanforprivacyfile /Users/piri/Library/Developer/Xcode/DerivedData/DoSurfApp-gsfzlkocnokhwogeccamufjbufgl/Build/Products/Debug-iphonesimulator/DoSurfApp.app/IQKeyboardToolbar_IQKeyboardToolbar.bundle -scanforprivacyfile /Users/piri/Library/Developer/Xcode/DerivedData/DoSurfApp-gsfzlkocnokhwogeccamufjbufgl/Build/Products/Debug-iphonesimulator/DoSurfApp.app/IQTextInputViewNotification_IQTextInputViewNotification.bundle -scanforprivacyfile /Users/piri/Library/Developer/Xcode/DerivedData/DoSurfApp-gsfzlkocnokhwogeccamufjbufgl/Build/Products/Debug-iphonesimulator/DoSurfApp.app/IQTextView_IQTextView.bundle -scanforprivacyfile /Users/piri/Library/Developer/Xcode/DerivedData/DoSurfApp-gsfzlkocnokhwogeccamufjbufgl/Build/Products/Debug-iphonesimulator/DoSurfApp.app/PlugIns/DoSurfWidgetExtensionExtension.appex -scanforprivacyfile /Users/piri/Library/Developer/Xcode/DerivedData/DoSurfApp-gsfzlkocnokhwogeccamufjbufgl/Build/Products/Debug-iphonesimulator/DoSurfApp.app/Promises_FBLPromises.bundle -scanforprivacyfile /Users/piri/Library/Developer/Xcode/DerivedData/DoSurfApp-gsfzlkocnokhwogeccamufjbufgl/Build/Products/Debug-iphonesimulator/DoSurfApp.app/RxSwift_RxCocoa.bundle -scanforprivacyfile /Users/piri/Library/Developer/Xcode/DerivedData/DoSurfApp-gsfzlkocnokhwogeccamufjbufgl/Build/Products/Debug-iphonesimulator/DoSurfApp.app/RxSwift_RxCocoaRuntime.bundle -scanforprivacyfile /Users/piri/Library/Developer/Xcode/DerivedData/DoSurfApp-gsfzlkocnokhwogeccamufjbufgl/Build/Products/Debug-iphonesimulator/DoSurfApp.app/RxSwift_RxRelay.bundle -scanforprivacyfile /Users/piri/Library/Developer/Xcode/DerivedData/DoSurfApp-gsfzlkocnokhwogeccamufjbufgl/Build/Products/Debug-iphonesimulator/DoSurfApp.app/RxSwift_RxSwift.bundle -scanforprivacyfile /Users/piri/Library/Developer/Xcode/DerivedData/DoSurfApp-gsfzlkocnokhwogeccamufjbufgl/Build/Products/Debug-iphonesimulator/DoSurfApp.app/SnapKit_SnapKit.bundle -scanforprivacyfile /Users/piri/Library/Developer/Xcode/DerivedData/DoSurfApp-gsfzlkocnokhwogeccamufjbufgl/Build/Products/Debug-iphonesimulator/DoSurfApp.app/Watch/DoSurfWatch\ Watch\ App.app -scanforprivacyfile /Users/piri/Library/Developer/Xcode/DerivedData/DoSurfApp-gsfzlkocnokhwogeccamufjbufgl/Build/Products/Debug-iphonesimulator/DoSurfApp.app/abseil_abslWrapper.bundle -scanforprivacyfile /Users/piri/Library/Developer/Xcode/DerivedData/DoSurfApp-gsfzlkocnokhwogeccamufjbufgl/Build/Products/Debug-iphonesimulator/DoSurfApp.app/gRPC_grpcWrapper.bundle -scanforprivacyfile /Users/piri/Library/Developer/Xcode/DerivedData/DoSurfApp-gsfzlkocnokhwogeccamufjbufgl/Build/Products/Debug-iphonesimulator/DoSurfApp.app/gRPC_grpcppWrapper.bundle -scanforprivacyfile /Users/piri/Library/Developer/Xcode/DerivedData/DoSurfApp-gsfzlkocnokhwogeccamufjbufgl/Build/Products/Debug-iphonesimulator/DoSurfApp.app/gRPC_opensslWrapper.bundle -scanforprivacyfile /Users/piri/Library/Developer/Xcode/DerivedData/DoSurfApp-gsfzlkocnokhwogeccamufjbufgl/Build/Products/Debug-iphonesimulator/DoSurfApp.app/leveldb_leveldb.bundle -scanforprivacyfile /Users/piri/Library/Developer/Xcode/DerivedData/DoSurfApp-gsfzlkocnokhwogeccamufjbufgl/Build/Products/Debug-iphonesimulator/DoSurfApp.app/nanopb_nanopb.bundle -o /Users/piri/Library/Developer/Xcode/DerivedData/DoSurfApp-gsfzlkocnokhwogeccamufjbufgl/Build/Products/Debug-iphonesimulator/DoSurfApp.app/Info.plist

CopySwiftLibs /Users/piri/Library/Developer/Xcode/DerivedData/DoSurfApp-gsfzlkocnokhwogeccamufjbufgl/Build/Products/Debug-iphonesimulator/DoSurfApp.app (in target 'DoSurfApp' from project 'DoSurfApp')
    cd /Users/piri/shared/active/DoSurf-iOS-iosclaw
    builtin-swiftStdLibTool --copy --verbose --sign - --scan-executable /Users/piri/Library/Developer/Xcode/DerivedData/DoSurfApp-gsfzlkocnokhwogeccamufjbufgl/Build/Products/Debug-iphonesimulator/DoSurfApp.app/DoSurfApp.debug.dylib --scan-folder /Users/piri/Library/Developer/Xcode/DerivedData/DoSurfApp-gsfzlkocnokhwogeccamufjbufgl/Build/Products/Debug-iphonesimulator/DoSurfApp.app/Frameworks --scan-folder /Users/piri/Library/Developer/Xcode/DerivedData/DoSurfApp-gsfzlkocnokhwogeccamufjbufgl/Build/Products/Debug-iphonesimulator/DoSurfApp.app/PlugIns --scan-folder /Users/piri/Library/Developer/Xcode/DerivedData/DoSurfApp-gsfzlkocnokhwogeccamufjbufgl/Build/Products/Debug-iphonesimulator/DoSurfApp.app/SystemExtensions --scan-folder /Users/piri/Library/Developer/Xcode/DerivedData/DoSurfApp-gsfzlkocnokhwogeccamufjbufgl/Build/Products/Debug-iphonesimulator/DoSurfApp.app/Extensions --platform iphonesimulator --toolchain /var/run/com.apple.security.cryptexd/mnt/com.apple.MobileAsset.MetalToolchain-v17.3.48.0.MfQi97/Metal.xctoolchain --toolchain /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain --destination /Users/piri/Library/Developer/Xcode/DerivedData/DoSurfApp-gsfzlkocnokhwogeccamufjbufgl/Build/Products/Debug-iphonesimulator/DoSurfApp.app/Frameworks --strip-bitcode --strip-bitcode-tool /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/bitcode_strip --emit-dependency-info /Users/piri/Library/Developer/Xcode/DerivedData/DoSurfApp-gsfzlkocnokhwogeccamufjbufgl/Build/Intermediates.noindex/DoSurfApp.build/Debug-iphonesimulator/DoSurfApp.build/SwiftStdLibToolInputDependencies.dep --filter-for-swift-os --back-deploy-swift-span

** BUILD SUCCEEDED **

```

## watch_build

- command: `xcodebuild -project DoSurfApp.xcodeproj -scheme DoSurfWatch Watch App -configuration Debug -destination generic/platform=watchOS Simulator build`
- exit_code: 0
- first_error: none
- optional: false
- log_file: /Users/piri/shared/active/DoSurf-iOS-iosclaw/collected_plan_watch/plan_related/qa_logs/watch_build_20260306_221113.log

### tail
```text

ProcessInfoPlistFile /Users/piri/Library/Developer/Xcode/DerivedData/DoSurfApp-gsfzlkocnokhwogeccamufjbufgl/Build/Products/Debug-watchsimulator/DoSurfWatch\ Watch\ App\ WatchKitExtension.appex/Info.plist /Users/piri/shared/active/DoSurf-iOS-iosclaw/DoSurfWatch-Watch-Extension-Info.plist (in target 'DoSurfWatch Watch App WatchKitExtension' from project 'DoSurfApp')
    cd /Users/piri/shared/active/DoSurf-iOS-iosclaw
    builtin-infoPlistUtility /Users/piri/shared/active/DoSurf-iOS-iosclaw/DoSurfWatch-Watch-Extension-Info.plist -producttype com.apple.product-type.watchkit2-extension -expandbuildsettings -format binary -platform watchsimulator -additionalcontentfile /Users/piri/Library/Developer/Xcode/DerivedData/DoSurfApp-gsfzlkocnokhwogeccamufjbufgl/Build/Intermediates.noindex/DoSurfApp.build/Debug-watchsimulator/DoSurfWatch\ Watch\ App\ WatchKitExtension.build/assetcatalog_generated_info.plist -o /Users/piri/Library/Developer/Xcode/DerivedData/DoSurfApp-gsfzlkocnokhwogeccamufjbufgl/Build/Products/Debug-watchsimulator/DoSurfWatch\ Watch\ App\ WatchKitExtension.appex/Info.plist
warning: 'CLKComplicationSupportedFamilies' has been deprecated starting in watchOS 7.0, use the ClockKit complications API instead. (in target 'DoSurfWatch Watch App WatchKitExtension' from project 'DoSurfApp')

ProcessInfoPlistFile /Users/piri/Library/Developer/Xcode/DerivedData/DoSurfApp-gsfzlkocnokhwogeccamufjbufgl/Build/Products/Debug-watchsimulator/DoSurfWatch\ Watch\ App.app/Info.plist /Users/piri/shared/active/DoSurf-iOS-iosclaw/DoSurfWatch-Watch-App-Info.plist (in target 'DoSurfWatch Watch App' from project 'DoSurfApp')
    cd /Users/piri/shared/active/DoSurf-iOS-iosclaw
    builtin-infoPlistUtility /Users/piri/shared/active/DoSurf-iOS-iosclaw/DoSurfWatch-Watch-App-Info.plist -producttype com.apple.product-type.application.watchapp2 -genpkginfo /Users/piri/Library/Developer/Xcode/DerivedData/DoSurfApp-gsfzlkocnokhwogeccamufjbufgl/Build/Products/Debug-watchsimulator/DoSurfWatch\ Watch\ App.app/PkgInfo -expandbuildsettings -format binary -platform watchsimulator -additionalcontentfile /Users/piri/Library/Developer/Xcode/DerivedData/DoSurfApp-gsfzlkocnokhwogeccamufjbufgl/Build/Intermediates.noindex/DoSurfApp.build/Debug-watchsimulator/DoSurfWatch\ Watch\ App.build/assetcatalog_generated_info.plist -scanforprivacyfile /Users/piri/Library/Developer/Xcode/DerivedData/DoSurfApp-gsfzlkocnokhwogeccamufjbufgl/Build/Products/Debug-watchsimulator/DoSurfWatch\ Watch\ App.app/PlugIns/DoSurfWatch\ Watch\ App\ WatchKitExtension.appex -o /Users/piri/Library/Developer/Xcode/DerivedData/DoSurfApp-gsfzlkocnokhwogeccamufjbufgl/Build/Products/Debug-watchsimulator/DoSurfWatch\ Watch\ App.app/Info.plist

ProcessInfoPlistFile /Users/piri/Library/Developer/Xcode/DerivedData/DoSurfApp-gsfzlkocnokhwogeccamufjbufgl/Build/Products/Debug-iphonesimulator/DoSurfApp.app/Info.plist /Users/piri/shared/active/DoSurf-iOS-iosclaw/DoSurfApp/App/Info.plist (in target 'DoSurfApp' from project 'DoSurfApp')
    cd /Users/piri/shared/active/DoSurf-iOS-iosclaw
    builtin-infoPlistUtility /Users/piri/shared/active/DoSurf-iOS-iosclaw/DoSurfApp/App/Info.plist -producttype com.apple.product-type.application -genpkginfo /Users/piri/Library/Developer/Xcode/DerivedData/DoSurfApp-gsfzlkocnokhwogeccamufjbufgl/Build/Products/Debug-iphonesimulator/DoSurfApp.app/PkgInfo -expandbuildsettings -format binary -platform iphonesimulator -additionalcontentfile /Users/piri/Library/Developer/Xcode/DerivedData/DoSurfApp-gsfzlkocnokhwogeccamufjbufgl/Build/Intermediates.noindex/DoSurfApp.build/Debug-iphonesimulator/DoSurfApp.build/Base.lproj/LaunchScreen-SBPartialInfo.plist -additionalcontentfile /Users/piri/Library/Developer/Xcode/DerivedData/DoSurfApp-gsfzlkocnokhwogeccamufjbufgl/Build/Intermediates.noindex/DoSurfApp.build/Debug-iphonesimulator/DoSurfApp.build/assetcatalog_generated_info.plist -scanforprivacyfile /Users/piri/Library/Developer/Xcode/DerivedData/DoSurfApp-gsfzlkocnokhwogeccamufjbufgl/Build/Products/Debug-iphonesimulator/DoSurfApp.app/Firebase_FirebaseCore.bundle -scanforprivacyfile /Users/piri/Library/Developer/Xcode/DerivedData/DoSurfApp-gsfzlkocnokhwogeccamufjbufgl/Build/Products/Debug-iphonesimulator/DoSurfApp.app/Firebase_FirebaseCoreExtension.bundle -scanforprivacyfile /Users/piri/Library/Developer/Xcode/DerivedData/DoSurfApp-gsfzlkocnokhwogeccamufjbufgl/Build/Products/Debug-iphonesimulator/DoSurfApp.app/Firebase_FirebaseCoreInternal.bundle -scanforprivacyfile /Users/piri/Library/Developer/Xcode/DerivedData/DoSurfApp-gsfzlkocnokhwogeccamufjbufgl/Build/Products/Debug-iphonesimulator/DoSurfApp.app/Firebase_FirebaseFirestore.bundle -scanforprivacyfile /Users/piri/Library/Developer/Xcode/DerivedData/DoSurfApp-gsfzlkocnokhwogeccamufjbufgl/Build/Products/Debug-iphonesimulator/DoSurfApp.app/Firebase_FirebaseInstallations.bundle -scanforprivacyfile /Users/piri/Library/Developer/Xcode/DerivedData/DoSurfApp-gsfzlkocnokhwogeccamufjbufgl/Build/Products/Debug-iphonesimulator/DoSurfApp.app/Frameworks/FirebaseAnalytics.framework -scanforprivacyfile /Users/piri/Library/Developer/Xcode/DerivedData/DoSurfApp-gsfzlkocnokhwogeccamufjbufgl/Build/Products/Debug-iphonesimulator/DoSurfApp.app/Frameworks/FirebaseFirestoreInternal.framework -scanforprivacyfile /Users/piri/Library/Developer/Xcode/DerivedData/DoSurfApp-gsfzlkocnokhwogeccamufjbufgl/Build/Products/Debug-iphonesimulator/DoSurfApp.app/Frameworks/GoogleAdsOnDeviceConversion.framework -scanforprivacyfile /Users/piri/Library/Developer/Xcode/DerivedData/DoSurfApp-gsfzlkocnokhwogeccamufjbufgl/Build/Products/Debug-iphonesimulator/DoSurfApp.app/Frameworks/GoogleAppMeasurement.framework -scanforprivacyfile /Users/piri/Library/Developer/Xcode/DerivedData/DoSurfApp-gsfzlkocnokhwogeccamufjbufgl/Build/Products/Debug-iphonesimulator/DoSurfApp.app/Frameworks/GoogleAppMeasurementIdentitySupport.framework -scanforprivacyfile /Users/piri/Library/Developer/Xcode/DerivedData/DoSurfApp-gsfzlkocnokhwogeccamufjbufgl/Build/Products/Debug-iphonesimulator/DoSurfApp.app/Frameworks/absl.framework -scanforprivacyfile /Users/piri/Library/Developer/Xcode/DerivedData/DoSurfApp-gsfzlkocnokhwogeccamufjbufgl/Build/Products/Debug-iphonesimulator/DoSurfApp.app/Frameworks/grpc.framework -scanforprivacyfile /Users/piri/Library/Developer/Xcode/DerivedData/DoSurfApp-gsfzlkocnokhwogeccamufjbufgl/Build/Products/Debug-iphonesimulator/DoSurfApp.app/Frameworks/grpcpp.framework -scanforprivacyfile /Users/piri/Library/Developer/Xcode/DerivedData/DoSurfApp-gsfzlkocnokhwogeccamufjbufgl/Build/Products/Debug-iphonesimulator/DoSurfApp.app/Frameworks/openssl_grpc.framework -scanforprivacyfile /Users/piri/Library/Developer/Xcode/DerivedData/DoSurfApp-gsfzlkocnokhwogeccamufjbufgl/Build/Products/Debug-iphonesimulator/DoSurfApp.app/GoogleUtilities_GoogleUtilities-AppDelegateSwizzler.bundle -scanforprivacyfile /Users/piri/Library/Developer/Xcode/DerivedData/DoSurfApp-gsfzlkocnokhwogeccamufjbufgl/Build/Products/Debug-iphonesimulator/DoSurfApp.app/GoogleUtilities_GoogleUtilities-Environment.bundle -scanforprivacyfile /Users/piri/Library/Developer/Xcode/DerivedData/DoSurfApp-gsfzlkocnokhwogeccamufjbufgl/Build/Products/Debug-iphonesimulator/DoSurfApp.app/GoogleUtilities_GoogleUtilities-Logger.bundle -scanforprivacyfile /Users/piri/Library/Developer/Xcode/DerivedData/DoSurfApp-gsfzlkocnokhwogeccamufjbufgl/Build/Products/Debug-iphonesimulator/DoSurfApp.app/GoogleUtilities_GoogleUtilities-MethodSwizzler.bundle -scanforprivacyfile /Users/piri/Library/Developer/Xcode/DerivedData/DoSurfApp-gsfzlkocnokhwogeccamufjbufgl/Build/Products/Debug-iphonesimulator/DoSurfApp.app/GoogleUtilities_GoogleUtilities-NSData.bundle -scanforprivacyfile /Users/piri/Library/Developer/Xcode/DerivedData/DoSurfApp-gsfzlkocnokhwogeccamufjbufgl/Build/Products/Debug-iphonesimulator/DoSurfApp.app/GoogleUtilities_GoogleUtilities-Network.bundle -scanforprivacyfile /Users/piri/Library/Developer/Xcode/DerivedData/DoSurfApp-gsfzlkocnokhwogeccamufjbufgl/Build/Products/Debug-iphonesimulator/DoSurfApp.app/GoogleUtilities_GoogleUtilities-Reachability.bundle -scanforprivacyfile /Users/piri/Library/Developer/Xcode/DerivedData/DoSurfApp-gsfzlkocnokhwogeccamufjbufgl/Build/Products/Debug-iphonesimulator/DoSurfApp.app/GoogleUtilities_GoogleUtilities-UserDefaults.bundle -scanforprivacyfile /Users/piri/Library/Developer/Xcode/DerivedData/DoSurfApp-gsfzlkocnokhwogeccamufjbufgl/Build/Products/Debug-iphonesimulator/DoSurfApp.app/IQKeyboardCore_IQKeyboardCore.bundle -scanforprivacyfile /Users/piri/Library/Developer/Xcode/DerivedData/DoSurfApp-gsfzlkocnokhwogeccamufjbufgl/Build/Products/Debug-iphonesimulator/DoSurfApp.app/IQKeyboardManagerSwift_IQKeyboardManagerSwift.bundle -scanforprivacyfile /Users/piri/Library/Developer/Xcode/DerivedData/DoSurfApp-gsfzlkocnokhwogeccamufjbufgl/Build/Products/Debug-iphonesimulator/DoSurfApp.app/IQKeyboardNotification_IQKeyboardNotification.bundle -scanforprivacyfile /Users/piri/Library/Developer/Xcode/DerivedData/DoSurfApp-gsfzlkocnokhwogeccamufjbufgl/Build/Products/Debug-iphonesimulator/DoSurfApp.app/IQKeyboardReturnManager_IQKeyboardReturnManager.bundle -scanforprivacyfile /Users/piri/Library/Developer/Xcode/DerivedData/DoSurfApp-gsfzlkocnokhwogeccamufjbufgl/Build/Products/Debug-iphonesimulator/DoSurfApp.app/IQKeyboardToolbarManager_IQKeyboardToolbarManager.bundle -scanforprivacyfile /Users/piri/Library/Developer/Xcode/DerivedData/DoSurfApp-gsfzlkocnokhwogeccamufjbufgl/Build/Products/Debug-iphonesimulator/DoSurfApp.app/IQKeyboardToolbar_IQKeyboardToolbar.bundle -scanforprivacyfile /Users/piri/Library/Developer/Xcode/DerivedData/DoSurfApp-gsfzlkocnokhwogeccamufjbufgl/Build/Products/Debug-iphonesimulator/DoSurfApp.app/IQTextInputViewNotification_IQTextInputViewNotification.bundle -scanforprivacyfile /Users/piri/Library/Developer/Xcode/DerivedData/DoSurfApp-gsfzlkocnokhwogeccamufjbufgl/Build/Products/Debug-iphonesimulator/DoSurfApp.app/IQTextView_IQTextView.bundle -scanforprivacyfile /Users/piri/Library/Developer/Xcode/DerivedData/DoSurfApp-gsfzlkocnokhwogeccamufjbufgl/Build/Products/Debug-iphonesimulator/DoSurfApp.app/PlugIns/DoSurfWidgetExtensionExtension.appex -scanforprivacyfile /Users/piri/Library/Developer/Xcode/DerivedData/DoSurfApp-gsfzlkocnokhwogeccamufjbufgl/Build/Products/Debug-iphonesimulator/DoSurfApp.app/Promises_FBLPromises.bundle -scanforprivacyfile /Users/piri/Library/Developer/Xcode/DerivedData/DoSurfApp-gsfzlkocnokhwogeccamufjbufgl/Build/Products/Debug-iphonesimulator/DoSurfApp.app/RxSwift_RxCocoa.bundle -scanforprivacyfile /Users/piri/Library/Developer/Xcode/DerivedData/DoSurfApp-gsfzlkocnokhwogeccamufjbufgl/Build/Products/Debug-iphonesimulator/DoSurfApp.app/RxSwift_RxCocoaRuntime.bundle -scanforprivacyfile /Users/piri/Library/Developer/Xcode/DerivedData/DoSurfApp-gsfzlkocnokhwogeccamufjbufgl/Build/Products/Debug-iphonesimulator/DoSurfApp.app/RxSwift_RxRelay.bundle -scanforprivacyfile /Users/piri/Library/Developer/Xcode/DerivedData/DoSurfApp-gsfzlkocnokhwogeccamufjbufgl/Build/Products/Debug-iphonesimulator/DoSurfApp.app/RxSwift_RxSwift.bundle -scanforprivacyfile /Users/piri/Library/Developer/Xcode/DerivedData/DoSurfApp-gsfzlkocnokhwogeccamufjbufgl/Build/Products/Debug-iphonesimulator/DoSurfApp.app/SnapKit_SnapKit.bundle -scanforprivacyfile /Users/piri/Library/Developer/Xcode/DerivedData/DoSurfApp-gsfzlkocnokhwogeccamufjbufgl/Build/Products/Debug-iphonesimulator/DoSurfApp.app/Watch/DoSurfWatch\ Watch\ App.app -scanforprivacyfile /Users/piri/Library/Developer/Xcode/DerivedData/DoSurfApp-gsfzlkocnokhwogeccamufjbufgl/Build/Products/Debug-iphonesimulator/DoSurfApp.app/abseil_abslWrapper.bundle -scanforprivacyfile /Users/piri/Library/Developer/Xcode/DerivedData/DoSurfApp-gsfzlkocnokhwogeccamufjbufgl/Build/Products/Debug-iphonesimulator/DoSurfApp.app/gRPC_grpcWrapper.bundle -scanforprivacyfile /Users/piri/Library/Developer/Xcode/DerivedData/DoSurfApp-gsfzlkocnokhwogeccamufjbufgl/Build/Products/Debug-iphonesimulator/DoSurfApp.app/gRPC_grpcppWrapper.bundle -scanforprivacyfile /Users/piri/Library/Developer/Xcode/DerivedData/DoSurfApp-gsfzlkocnokhwogeccamufjbufgl/Build/Products/Debug-iphonesimulator/DoSurfApp.app/gRPC_opensslWrapper.bundle -scanforprivacyfile /Users/piri/Library/Developer/Xcode/DerivedData/DoSurfApp-gsfzlkocnokhwogeccamufjbufgl/Build/Products/Debug-iphonesimulator/DoSurfApp.app/leveldb_leveldb.bundle -scanforprivacyfile /Users/piri/Library/Developer/Xcode/DerivedData/DoSurfApp-gsfzlkocnokhwogeccamufjbufgl/Build/Products/Debug-iphonesimulator/DoSurfApp.app/nanopb_nanopb.bundle -o /Users/piri/Library/Developer/Xcode/DerivedData/DoSurfApp-gsfzlkocnokhwogeccamufjbufgl/Build/Products/Debug-iphonesimulator/DoSurfApp.app/Info.plist

CopySwiftLibs /Users/piri/Library/Developer/Xcode/DerivedData/DoSurfApp-gsfzlkocnokhwogeccamufjbufgl/Build/Products/Debug-iphonesimulator/DoSurfApp.app (in target 'DoSurfApp' from project 'DoSurfApp')
    cd /Users/piri/shared/active/DoSurf-iOS-iosclaw
    builtin-swiftStdLibTool --copy --verbose --sign - --scan-executable /Users/piri/Library/Developer/Xcode/DerivedData/DoSurfApp-gsfzlkocnokhwogeccamufjbufgl/Build/Products/Debug-iphonesimulator/DoSurfApp.app/DoSurfApp.debug.dylib --scan-folder /Users/piri/Library/Developer/Xcode/DerivedData/DoSurfApp-gsfzlkocnokhwogeccamufjbufgl/Build/Products/Debug-iphonesimulator/DoSurfApp.app/Frameworks --scan-folder /Users/piri/Library/Developer/Xcode/DerivedData/DoSurfApp-gsfzlkocnokhwogeccamufjbufgl/Build/Products/Debug-iphonesimulator/DoSurfApp.app/PlugIns --scan-folder /Users/piri/Library/Developer/Xcode/DerivedData/DoSurfApp-gsfzlkocnokhwogeccamufjbufgl/Build/Products/Debug-iphonesimulator/DoSurfApp.app/SystemExtensions --scan-folder /Users/piri/Library/Developer/Xcode/DerivedData/DoSurfApp-gsfzlkocnokhwogeccamufjbufgl/Build/Products/Debug-iphonesimulator/DoSurfApp.app/Extensions --platform iphonesimulator --toolchain /var/run/com.apple.security.cryptexd/mnt/com.apple.MobileAsset.MetalToolchain-v17.3.48.0.MfQi97/Metal.xctoolchain --toolchain /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain --destination /Users/piri/Library/Developer/Xcode/DerivedData/DoSurfApp-gsfzlkocnokhwogeccamufjbufgl/Build/Products/Debug-iphonesimulator/DoSurfApp.app/Frameworks --strip-bitcode --strip-bitcode-tool /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/bitcode_strip --emit-dependency-info /Users/piri/Library/Developer/Xcode/DerivedData/DoSurfApp-gsfzlkocnokhwogeccamufjbufgl/Build/Intermediates.noindex/DoSurfApp.build/Debug-iphonesimulator/DoSurfApp.build/SwiftStdLibToolInputDependencies.dep --filter-for-swift-os --back-deploy-swift-span

** BUILD SUCCEEDED **

```

## ios_test

- command: `xcodebuild -project DoSurfApp.xcodeproj -scheme DoSurfApp -configuration Debug -destination generic/platform=iOS Simulator test`
- exit_code: 66
- first_error: xcodebuild: error: Scheme DoSurfApp is not currently configured for the test action.
- optional: false
- log_file: /Users/piri/shared/active/DoSurf-iOS-iosclaw/collected_plan_watch/plan_related/qa_logs/ios_test_20260306_221113.log

### tail
```text
  IQTextInputViewNotification: https://github.com/hackiftekhar/IQTextInputViewNotification.git @ 1.0.9
  IQKeyboardToolbarManager: https://github.com/hackiftekhar/IQKeyboardToolbarManager.git @ 1.1.4
  IQTextView: https://github.com/hackiftekhar/IQTextView.git @ 1.0.5
  Promises: https://github.com/google/promises.git @ 2.4.0
  RxSwift: https://github.com/ReactiveX/RxSwift.git @ 6.9.0
  GoogleAdsOnDeviceConversion: https://github.com/googleads/google-ads-on-device-conversion-ios-sdk @ 3.0.0
  GTMSessionFetcher: https://github.com/google/gtm-session-fetcher.git @ 5.0.0
  AppCheck: https://github.com/google/app-check.git @ 11.2.0
  SwiftProtobuf: https://github.com/apple/swift-protobuf.git @ 1.31.1
  SnapKit: https://github.com/SnapKit/SnapKit.git @ 5.7.1
  InteropForGoogle: https://github.com/google/interop-ios-for-google-sdks.git @ 101.0.0
  IQKeyboardToolbar: https://github.com/hackiftekhar/IQKeyboardToolbar.git @ 1.1.3
  gRPC: https://github.com/google/grpc-binary.git @ 1.69.1
  nanopb: https://github.com/firebase/nanopb.git @ 2.30910.0
  IQKeyboardNotification: https://github.com/hackiftekhar/IQKeyboardNotification.git @ 1.0.6
  IQKeyboardReturnManager: https://github.com/hackiftekhar/IQKeyboardReturnManager.git @ 1.0.6

2026-03-06 22:11:39.612 xcodebuild[81796:16434149] Writing error result bundle to /var/folders/f_/qzxc8b5x2m1fvln820vfkd1c0000gp/T/ResultBundle_2026-06-03_22-11-0039.xcresult
xcodebuild: error: Scheme DoSurfApp is not currently configured for the test action.

```

## swiftlint_check

- command: `sh -c command -v swiftlint >/dev/null 2>&1 && swiftlint version || true`
- exit_code: 0
- first_error: none
- optional: true
- log_file: /Users/piri/shared/active/DoSurf-iOS-iosclaw/collected_plan_watch/plan_related/qa_logs/swiftlint_check_20260306_221113.log

### tail
```text
```

## result

- status: FAIL (1 hard-failed)
- optional_fail_count: 0
