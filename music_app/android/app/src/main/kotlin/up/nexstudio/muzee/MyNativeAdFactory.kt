package up.nexstudio.muzee

import android.content.Context
import android.graphics.Color
import android.view.LayoutInflater
import android.view.View
import android.widget.ImageView
import android.widget.TextView
import com.google.android.gms.ads.nativead.MediaView
import com.google.android.gms.ads.nativead.NativeAd
import com.google.android.gms.ads.nativead.NativeAdView
import io.flutter.plugins.googlemobileads.GoogleMobileAdsPlugin

class SongNativeAdCellFactory(val context: Context) : GoogleMobileAdsPlugin.NativeAdFactory {
    override fun createNativeAd(nativeAd: NativeAd, customOptions: Map<String, Any>?): NativeAdView {
        val adView = LayoutInflater.from(context).inflate(R.layout.native_cell, null) as NativeAdView

        // Ánh xạ view
        val headlineView = adView.findViewById<TextView>(R.id.ad_headline)
        val iconView = adView.findViewById<ImageView>(R.id.ad_app_icon)
        val bodyView = adView.findViewById<TextView>(R.id.ad_body)

        // Gán view cho NativeAdView
        adView.headlineView = headlineView
        adView.iconView = iconView
        adView.bodyView = bodyView

        // Gán dữ liệu từ NativeAd
        headlineView.text = nativeAd.headline

        if (nativeAd.icon != null) {
            iconView.setImageDrawable(nativeAd.icon?.drawable)
            iconView.visibility = View.VISIBLE
        } else {
            iconView.visibility = View.GONE
        }

        if (nativeAd.body != null) {
            bodyView.text = nativeAd.body
            bodyView.visibility = View.VISIBLE
        } else {
            bodyView.visibility = View.GONE
        }

        adView.setNativeAd(nativeAd)
        return adView
    }
}


class PlaylistNativeAdFactory(private val context: Context) : GoogleMobileAdsPlugin.NativeAdFactory {
    override fun createNativeAd(nativeAd: NativeAd, customOptions: MutableMap<String, Any>?): NativeAdView {
        val inflater = LayoutInflater.from(context)
        val adView = inflater.inflate(R.layout.native_ad_playlist, null) as NativeAdView

        // Bind views
        val headlineView = adView.findViewById<TextView>(R.id.ad_headline)
        val bodyView = adView.findViewById<TextView>(R.id.ad_body)
        val mediaView = adView.findViewById<MediaView>(R.id.ad_media)

        // Gán vào adView
        adView.headlineView = headlineView
        adView.bodyView = bodyView
        adView.mediaView = mediaView

        // Set nội dung
        headlineView.text = nativeAd.headline

        if (nativeAd.body != null) {
            bodyView.text = nativeAd.body
            bodyView.visibility = View.VISIBLE
        } else {
            bodyView.visibility = View.GONE
        }

        adView.setNativeAd(nativeAd)
        return adView
    }
}
