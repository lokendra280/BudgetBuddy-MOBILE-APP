package com.hamrobudget  // ← match exactly with MainActivity.kt

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class HomeWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: android.content.SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->

            val currency   = widgetData.getString("currency", "") ?: ""
            val totalSpent = widgetData.getFloat("total_spent", -1f)
            val limit      = widgetData.getFloat("monthly_limit", -1f)
            val remaining  = widgetData.getFloat("remaining", -1f)
            val updated    = widgetData.getString("last_updated", "") ?: ""

            // Tap → open MainActivity
            val intent = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            val pendingIntent = PendingIntent.getActivity(
                context, 0, intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )

            val views = RemoteViews(context.packageName, R.layout.home_widget)

            if (totalSpent < 0f || limit < 0f) {
                views.setTextViewText(R.id.widget_remaining, "Open app to sync")
                views.setTextViewText(R.id.widget_spent, "No data yet")
                views.setTextViewText(R.id.widget_updated, "")
            } else {
                views.setTextViewText(
                    R.id.widget_remaining,
                    "%s%.2f".format(currency, remaining)
                )
                views.setTextViewText(
                    R.id.widget_spent,
                    "Spent: %s%.2f / %s%.2f".format(currency, totalSpent, currency, limit)
                )
                views.setTextViewText(
                    R.id.widget_updated,
                    if (updated.isNotEmpty()) "Updated $updated" else ""
                )
            }

            views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}