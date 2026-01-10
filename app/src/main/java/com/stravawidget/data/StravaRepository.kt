package com.stravawidget.data

import android.content.Context
import com.stravawidget.BuildConfig
import com.stravawidget.api.Activity
import com.stravawidget.api.StravaClient
import java.time.LocalDate
import java.time.ZoneId
import java.time.format.DateTimeFormatter
import java.time.temporal.ChronoUnit

class StravaRepository(context: Context) {

    private val tokenStorage = TokenStorage(context)
    private val activityCache = ActivityCache(context)
    private val api = StravaClient.api

    val isLoggedIn: Boolean
        get() = tokenStorage.isLoggedIn

    suspend fun exchangeCodeForTokens(code: String): Result<Unit> {
        return try {
            val response = api.exchangeToken(
                clientId = BuildConfig.STRAVA_CLIENT_ID,
                clientSecret = BuildConfig.STRAVA_CLIENT_SECRET,
                code = code
            )
            tokenStorage.saveTokens(
                accessToken = response.access_token,
                refreshToken = response.refresh_token,
                expiresAt = response.expires_at
            )
            Result.success(Unit)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    private suspend fun refreshTokenIfNeeded(): Boolean {
        if (!tokenStorage.isTokenExpired) return true

        val refreshToken = tokenStorage.refreshToken ?: return false

        return try {
            val response = api.refreshToken(
                clientId = BuildConfig.STRAVA_CLIENT_ID,
                clientSecret = BuildConfig.STRAVA_CLIENT_SECRET,
                refreshToken = refreshToken
            )
            tokenStorage.saveTokens(
                accessToken = response.access_token,
                refreshToken = response.refresh_token,
                expiresAt = response.expires_at
            )
            true
        } catch (e: Exception) {
            false
        }
    }

    suspend fun syncActivities(): Result<Map<String, Int>> {
        if (!isLoggedIn) return Result.failure(Exception("Not logged in"))

        if (!refreshTokenIfNeeded()) {
            return Result.failure(Exception("Failed to refresh token"))
        }

        val accessToken = tokenStorage.accessToken ?: return Result.failure(Exception("No access token"))

        return try {
            val after = getStartOfPeriod()
            val activities = api.getActivities(
                authorization = "Bearer $accessToken",
                after = after
            )

            val levels = calculateLevels(activities)
            activityCache.saveActivityLevels(levels)

            Result.success(levels)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    fun getCachedActivityLevels(): Map<String, Int> {
        return activityCache.getActivityLevels()
    }

    private fun getStartOfPeriod(): Long {
        val today = LocalDate.now()
        val startDate = today.minusDays(91)
        return startDate.atStartOfDay(ZoneId.systemDefault()).toEpochSecond()
    }

    private fun calculateLevels(activities: List<Activity>): Map<String, Int> {
        // Group activities by date and sum moving_time
        val minutesByDate = mutableMapOf<String, Int>()

        for (activity in activities) {
            // Extract date from start_date_local (first 10 chars: YYYY-MM-DD)
            val date = activity.start_date_local.take(10)
            val minutes = activity.moving_time / 60
            minutesByDate[date] = (minutesByDate[date] ?: 0) + minutes
        }

        // Convert minutes to levels
        return minutesByDate.mapValues { (_, minutes) ->
            when {
                minutes == 0 -> 0
                minutes < 30 -> 1
                minutes < 60 -> 2
                minutes < 90 -> 3
                else -> 4
            }
        }
    }

    fun logout() {
        tokenStorage.clear()
        activityCache.clear()
    }

    companion object {
        private const val WEEKS_TO_SHOW = 13
        private const val DAYS_TO_SHOW = WEEKS_TO_SHOW * 7

        fun getGridDates(): List<LocalDate?> {
            val today = LocalDate.now()
            val currentDayOfWeek = today.dayOfWeek.value % 7 // Sunday = 0

            // End date is Saturday of current week
            val endDate = today.plusDays((6 - currentDayOfWeek).toLong())
            // Start date is Sunday 12 weeks before
            val startDate = endDate.minusDays(DAYS_TO_SHOW.toLong() - 1)

            val dates = mutableListOf<LocalDate?>()

            // Build grid: 7 rows (days) x 13 columns (weeks)
            // Row 0 = Sunday, Row 6 = Saturday
            for (dayOfWeek in 0..6) {
                for (week in 0 until WEEKS_TO_SHOW) {
                    val date = startDate.plusDays((week * 7 + dayOfWeek).toLong())
                    // Hide future dates
                    if (date.isAfter(today)) {
                        dates.add(null)
                    } else {
                        dates.add(date)
                    }
                }
            }

            return dates
        }

        fun formatDate(date: LocalDate): String {
            return date.format(DateTimeFormatter.ISO_LOCAL_DATE)
        }
    }
}
