package up.nexstudio.muzee

import android.app.Application
import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build

/**
 * Creates Muzee's own channel for push notifications (suggestions, new
 * releases), so people can mute those in Android's settings without
 * touching anything else. FCM posts to it (default_notification_channel_id
 * in the manifest).
 */
class MuzeeApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val channel = NotificationChannel(
            getString(R.string.push_channel_id),
            getString(R.string.push_channel_name),
            NotificationManager.IMPORTANCE_DEFAULT,
        ).apply {
            description = getString(R.string.push_channel_description)
        }
        getSystemService(NotificationManager::class.java)
            ?.createNotificationChannel(channel)
    }
}
