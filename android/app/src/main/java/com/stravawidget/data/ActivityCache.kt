package com.stravawidget.data

import android.content.Context
import android.content.SharedPreferences
import com.google.gson.Gson
import com.google.gson.reflect.TypeToken

class ActivityCache(context: Context) {

    private val prefs: SharedPreferences = context.getSharedPreferences(
        "activity_cache",
        Context.MODE_PRIVATE
    )

    private val gson = Gson()

    companion object {
        private const val KEY_ACTIVITY_LEVELS = "activity_levels"
        private const val KEY_LAST_SYNC = "last_sync"
    }

    fun saveActivityLevels(levels: Map<String, Int>) {
        val json = gson.toJson(levels)
        prefs.edit()
            .putString(KEY_ACTIVITY_LEVELS, json)
            .putLong(KEY_LAST_SYNC, System.currentTimeMillis())
            .apply()
    }

    fun getActivityLevels(): Map<String, Int> {
        val json = prefs.getString(KEY_ACTIVITY_LEVELS, null) ?: return emptyMap()
        val type = object : TypeToken<Map<String, Int>>() {}.type
        return try {
            gson.fromJson(json, type) ?: emptyMap()
        } catch (e: Exception) {
            emptyMap()
        }
    }

    fun getLastSyncTime(): Long {
        return prefs.getLong(KEY_LAST_SYNC, 0)
    }

    fun clear() {
        prefs.edit().clear().apply()
    }
}
