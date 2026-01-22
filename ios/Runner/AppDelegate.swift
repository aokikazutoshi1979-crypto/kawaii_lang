// ios/Runner/AppDelegate.swift
import UIKit
import Flutter
import FBSDKCoreKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    ApplicationDelegate.shared.application(
      application,
      didFinishLaunchingWithOptions: launchOptions
    )

    Settings.shared.isAdvertiserTrackingEnabled = false
    Settings.shared.isAdvertiserIDCollectionEnabled = false
    Settings.shared.isAutoLogAppEventsEnabled = true

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // ✅ 追加：アプリがアクティブになったときにSDKへ通知
  override func applicationDidBecomeActive(_ application: UIApplication) {
    AppEvents.shared.activateApp()
  }

  override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey : Any] = [:]
  ) -> Bool {
    ApplicationDelegate.shared.application(app, open: url, options: options)
    return super.application(app, open: url, options: options)
  }
}
