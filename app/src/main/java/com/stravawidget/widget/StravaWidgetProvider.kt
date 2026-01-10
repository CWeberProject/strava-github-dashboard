package com.stravawidget.widget

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.widget.RemoteViews
import com.stravawidget.R
import com.stravawidget.StravaAuthActivity
import com.stravawidget.data.StravaRepository
import java.time.LocalDate

class StravaWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            updateWidget(context, appWidgetManager, appWidgetId)
        }
    }

    override fun onEnabled(context: Context) {
        super.onEnabled(context)
        // Schedule sync when first widget is added
        val repository = StravaRepository(context)
        if (repository.isLoggedIn) {
            SyncWorker.schedulePeriodicSync(context)
        }
    }

    companion object {
        private const val WEEKS = 13
        private const val DAYS = 7

        private val ROW_IDS = intArrayOf(
            R.id.row_0, R.id.row_1, R.id.row_2, R.id.row_3,
            R.id.row_4, R.id.row_5, R.id.row_6
        )

        private val LEVEL_DRAWABLES = intArrayOf(
            R.drawable.cell_level_0,
            R.drawable.cell_level_1,
            R.drawable.cell_level_2,
            R.drawable.cell_level_3,
            R.drawable.cell_level_4
        )

        fun updateAllWidgets(context: Context) {
            val appWidgetManager = AppWidgetManager.getInstance(context)
            val componentName = ComponentName(context, StravaWidgetProvider::class.java)
            val appWidgetIds = appWidgetManager.getAppWidgetIds(componentName)

            for (appWidgetId in appWidgetIds) {
                updateWidget(context, appWidgetManager, appWidgetId)
            }
        }

        private fun updateWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int
        ) {
            val repository = StravaRepository(context)
            val activityLevels = repository.getCachedActivityLevels()
            val gridDates = StravaRepository.getGridDates()

            val views = RemoteViews(context.packageName, R.layout.widget_layout)

            // Clear existing cells
            for (rowId in ROW_IDS) {
                views.removeAllViews(rowId)
            }

            // Build the grid
            val today = LocalDate.now()
            var dateIndex = 0

            for (dayOfWeek in 0 until DAYS) {
                for (week in 0 until WEEKS) {
                    val date = gridDates.getOrNull(dateIndex)
                    dateIndex++

                    val cellViews = RemoteViews(context.packageName, R.layout.widget_cell)

                    if (date == null || date.isAfter(today)) {
                        // Future date or null - make invisible
                        cellViews.setInt(R.id.widget_cell, "setVisibility", android.view.View.INVISIBLE)
                    } else {
                        cellViews.setInt(R.id.widget_cell, "setVisibility", android.view.View.VISIBLE)
                        val dateStr = StravaRepository.formatDate(date)
                        val level = activityLevels[dateStr] ?: 0
                        val drawableId = LEVEL_DRAWABLES[level.coerceIn(0, 4)]
                        cellViews.setInt(R.id.widget_cell, "setBackgroundResource", drawableId)
                    }

                    views.addView(ROW_IDS[dayOfWeek], cellViews)
                }
            }

            // Set click action
            val clickIntent = if (repository.isLoggedIn) {
                // Open Strava app
                Intent(Intent.ACTION_VIEW, Uri.parse("strava://feed")).apply {
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK
                }
            } else {
                // Open auth activity
                Intent(context, StravaAuthActivity::class.java)
            }

            val pendingIntent = PendingIntent.getActivity(
                context,
                appWidgetId,
                clickIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )

            views.setOnClickPendingIntent(R.id.widget_container, pendingIntent)

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
