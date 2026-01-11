package com.stravawidget.widget

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.util.TypedValue
import android.widget.RemoteViews
import com.stravawidget.R
import com.stravawidget.StravaAuthActivity
import com.stravawidget.data.StravaRepository
import java.time.LocalDate

/**
 * Holds calculated grid parameters based on widget dimensions
 */
data class GridParams(
    val columns: Int,
    val cellSizeDp: Float,
    val cellMarginDp: Float,
    val useLargeCell: Boolean
)

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

    override fun onAppWidgetOptionsChanged(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        newOptions: Bundle
    ) {
        super.onAppWidgetOptionsChanged(context, appWidgetManager, appWidgetId, newOptions)
        // Redraw widget when resized
        updateWidget(context, appWidgetManager, appWidgetId)
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
        private const val DAYS = 7

        // Base dimensions for 1-row height widgets (in dp)
        private const val BASE_CELL_SIZE_DP = 11.2f
        private const val BASE_CELL_MARGIN_DP = 1.4f
        private const val WIDGET_PADDING_DP = 16f  // 8dp on each side

        // Large cell dimensions for vertically scaled widgets (in dp)
        private const val LARGE_CELL_SIZE_DP = 18f
        private const val LARGE_CELL_MARGIN_DP = 2.2f

        // Height threshold for switching to large cells
        private const val LARGE_CELL_HEIGHT_THRESHOLD_DP = 120f

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

        /**
         * Calculate grid parameters based on widget dimensions.
         * - Horizontal scaling: more columns, same cell size
         * - Vertical scaling: larger cells, fewer columns
         */
        private fun calculateGridParams(widthDp: Int, heightDp: Int): GridParams {
            // Determine if we should use large cells based on height
            val useLargeCell = heightDp > LARGE_CELL_HEIGHT_THRESHOLD_DP

            val cellSize: Float
            val cellMargin: Float

            if (useLargeCell) {
                cellSize = LARGE_CELL_SIZE_DP
                cellMargin = LARGE_CELL_MARGIN_DP
            } else {
                cellSize = BASE_CELL_SIZE_DP
                cellMargin = BASE_CELL_MARGIN_DP
            }

            // Calculate columns based on available width with current cell size
            val availableWidth = widthDp - WIDGET_PADDING_DP
            val cellWithMargin = cellSize + 2 * cellMargin
            val columns = (availableWidth / cellWithMargin).toInt().coerceIn(7, 52)

            return GridParams(columns, cellSize, cellMargin, useLargeCell)
        }

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
            // Get widget dimensions to calculate grid parameters
            val options = appWidgetManager.getAppWidgetOptions(appWidgetId)
            val widthDp = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, 110)
            val heightDp = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT, 40)
            val gridParams = calculateGridParams(widthDp, heightDp)

            val repository = StravaRepository(context)
            val activityLevels = repository.getCachedActivityLevels()
            val gridDates = StravaRepository.getGridDates(gridParams.columns)

            val views = RemoteViews(context.packageName, R.layout.widget_layout)

            // Clear existing cells
            for (rowId in ROW_IDS) {
                views.removeAllViews(rowId)
            }

            // Select cell layout based on size
            val cellLayoutId = if (gridParams.useLargeCell) {
                R.layout.widget_cell_large
            } else {
                R.layout.widget_cell
            }

            // Build the grid
            val today = LocalDate.now()
            var dateIndex = 0

            for (dayOfWeek in 0 until DAYS) {
                for (week in 0 until gridParams.columns) {
                    val date = gridDates.getOrNull(dateIndex)
                    dateIndex++

                    val cellViews = RemoteViews(context.packageName, cellLayoutId)

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
                // Open Strava app using package name, with fallback to Play Store
                val stravaPackage = "com.strava"
                val launchIntent = context.packageManager.getLaunchIntentForPackage(stravaPackage)
                launchIntent ?: Intent(
                    Intent.ACTION_VIEW,
                    Uri.parse("https://play.google.com/store/apps/details?id=$stravaPackage")
                )
            } else {
                // Open auth activity
                Intent(context, StravaAuthActivity::class.java)
            }
            clickIntent.flags = Intent.FLAG_ACTIVITY_NEW_TASK

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
