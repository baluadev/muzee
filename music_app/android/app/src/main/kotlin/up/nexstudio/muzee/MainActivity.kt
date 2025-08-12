package up.nexstudio.muzee

import io.flutter.embedding.android.FlutterActivity
//import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugins.googlemobileads.GoogleMobileAdsPlugin
import com.ryanheise.audioservice.AudioServiceActivity;

class MainActivity: AudioServiceActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        GoogleMobileAdsPlugin.registerNativeAdFactory(
                flutterEngine, "songNativeAds", SongNativeAdCellFactory(context))
        GoogleMobileAdsPlugin.registerNativeAdFactory(
            flutterEngine, "playlistNativeAds", PlaylistNativeAdFactory(context))
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        super.cleanUpFlutterEngine(flutterEngine)
        GoogleMobileAdsPlugin.unregisterNativeAdFactory(flutterEngine, "songNativeAds")
        GoogleMobileAdsPlugin.unregisterNativeAdFactory(flutterEngine, "playlistNativeAds")
    }
}

