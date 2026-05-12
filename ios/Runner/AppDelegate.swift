import Flutter
import UIKit
import GoogleMaps

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    /*
     ╔══════════════════════════════════════════════════════════════╗
     ║  INSIRA SUA API KEY DO GOOGLE MAPS AQUI (iOS)              ║
     ║  Obtenha em: https://console.cloud.google.com/             ║
     ║  Ative as APIs: Maps SDK for iOS                           ║
     ╚══════════════════════════════════════════════════════════════╝
    */
    GMSServices.provideAPIKey("SUA_GOOGLE_MAPS_API_KEY_AQUI")

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
