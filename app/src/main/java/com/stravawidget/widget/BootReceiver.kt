package com.stravawidget.widget

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import com.stravawidget.data.StravaRepository

class BootReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent?) {
        if (intent?.action == Intent.ACTION_BOOT_COMPLETED) {
            val repository = StravaRepository(context)

            if (repository.isLoggedIn) {
                // Reschedule periodic sync after boot
                SyncWorker.schedulePeriodicSync(context)
                // Trigger immediate sync to refresh widget
                SyncWorker.syncNow(context)
            }
        }
    }
}
