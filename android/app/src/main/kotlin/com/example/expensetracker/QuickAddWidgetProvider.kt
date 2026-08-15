// android/app/src/main/kotlin/<your/package/path>/QuickAddWidgetProvider.kt
// Replaces AddExpenseWidgetProvider.kt.

package com.hamrobudget 

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

class QuickAddWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.quick_add_widget).apply {
                setOnClickPendingIntent(
                    R.id.widget_expense_zone,
                    HomeWidgetLaunchIntent.getActivity(
                        context, MainActivity::class.java, Uri.parse("budgetbuddy://add-expense")
                    )
                )
                setOnClickPendingIntent(
                    R.id.widget_income_zone,
                    HomeWidgetLaunchIntent.getActivity(
                        context, MainActivity::class.java, Uri.parse("budgetbuddy://add-income")
                    )
                )
                setOnClickPendingIntent(
                    R.id.widget_voice_zone,
                    HomeWidgetLaunchIntent.getActivity(
                        context, MainActivity::class.java, Uri.parse("budgetbuddy://voice-entry")
                    )
                )
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}