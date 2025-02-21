import Flutter
import UIKit
import GoogleMaps

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    //If ever go back to radar download sdk and then uncomment below
    //Radar.initialize(publishableKey: "prj_test_pk_8a63cc917387e0f16a796e8a61b3eb0c3660ef6f")

    //This is the google map api, this is so that the app will not crash when starting
    // Read API key from Info.plist
        if let apiKey = Bundle.main.infoDictionary?["GOOGLE_MAPS_API_KEY"] as? String {
          GMSServices.provideAPIKey(apiKey)
        } else {
          fatalError("Google Maps API Key not set in Info.plist")
        }

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
