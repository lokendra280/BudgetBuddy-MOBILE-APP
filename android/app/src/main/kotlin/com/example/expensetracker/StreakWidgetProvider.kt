// Duolingo-style streak widget: piggy mascot (happy / worried / sad),
// 🔥 streak, a nudge that changes during the day, and — in the wider
// layout — today's spend, budget left and an "+ Add" button.
//
// Data is written by lib/features/home/services/widget_sync_service.dart
// (all values are Strings). Mood/message logic mirrors
// ios/StreakWidget/StreakWidget.swift — keep the two in sync.

package com.hamrobudget

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.os.Bundle
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Locale

class StreakWidgetProvider : HomeWidgetProvider() {

    private enum class Mood { HAPPY, WORRIED, SAD }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { id ->
            val options = appWidgetManager.getAppWidgetOptions(id)
            appWidgetManager.updateAppWidget(id, build(context, widgetData, options))
        }
    }

    /** Re-render with the other layout when the user resizes the widget. */
    override fun onAppWidgetOptionsChanged(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        newOptions: Bundle
    ) {
        val prefs = context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
        appWidgetManager.updateAppWidget(appWidgetId, build(context, prefs, newOptions))
    }

    private fun build(context: Context, d: SharedPreferences, options: Bundle?): RemoteViews {
        fun s(key: String) = d.getString(key, "") ?: ""

        val dayFmt = SimpleDateFormat("yyyy-MM-dd", Locale.US)
        val cal = Calendar.getInstance()
        val today = dayFmt.format(cal.time)
        val hour = cal.get(Calendar.HOUR_OF_DAY)
        val yesterday = dayFmt.format(
            (cal.clone() as Calendar).apply { add(Calendar.DAY_OF_YEAR, -1) }.time
        )
        val monthKey = today.substring(0, 7)

        val rawStreak = s("bb_streak").toIntOrNull() ?: 0
        val lastActive = s("bb_last_active")
        val streakAlive = lastActive == today || lastActive == yesterday
        val streak = if (streakAlive) rawStreak else 0
        val streakBroken = !streakAlive && rawStreak > 0

        val loggedToday = s("bb_last_log") == today
        val todaySpent = if (s("bb_today_date") == today) s("bb_today_spent") else s("bb_zero")

        val hasBudget = s("bb_has_budget") == "1" && s("bb_month_key") == monthKey
        val pct = if (hasBudget) s("bb_budget_pct").toDoubleOrNull() ?: 0.0 else 0.0
        val hide = s("bb_hide") == "1"

        val (mood, title, message) = when {
            hasBudget && pct > 1 -> Triple(Mood.SAD, "Over budget", "Let's slow down spending 💸")
            streakBroken -> Triple(Mood.SAD, "Streak lost", "Open the app to start a new one")
            !loggedToday && hour >= 20 ->
                if (streak > 0) Triple(Mood.WORRIED, "$streak-day streak!", "Log today's spending before midnight")
                else Triple(Mood.WORRIED, "Quick check-in?", "Log today's spending")
            !loggedToday && hour >= 12 ->
                Triple(Mood.WORRIED, "Haven't logged today 👀", "It only takes a few seconds")
            !loggedToday -> Triple(Mood.HAPPY, "Good morning!", "Ready to track today?")
            hasBudget && pct >= 0.85 ->
                Triple(Mood.WORRIED, "Budget almost gone", "Spend carefully this month")
            else -> Triple(Mood.HAPPY, "Nice work!", "You're on track today")
        }

        // ≥ 250dp wide → medium layout with numbers + Add button.
        val minWidth = options?.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, 0) ?: 0
        val wide = minWidth >= 250
        val layout = if (wide) R.layout.streak_widget_medium else R.layout.streak_widget_small

        val addIntent = HomeWidgetLaunchIntent.getActivity(
            context, MainActivity::class.java, Uri.parse("budgetbuddy://add-expense")
        )
        val homeIntent = HomeWidgetLaunchIntent.getActivity(
            context, MainActivity::class.java, Uri.parse("budgetbuddy://dashboard")
        )

        return RemoteViews(context.packageName, layout).apply {
            setInt(
                R.id.widget_root, "setBackgroundResource",
                when (mood) {
                    Mood.HAPPY -> R.drawable.streak_bg_happy
                    Mood.WORRIED -> R.drawable.streak_bg_worried
                    Mood.SAD -> R.drawable.streak_bg_sad
                }
            )
            setImageViewResource(
                R.id.piggy,
                when (mood) {
                    Mood.HAPPY -> R.drawable.piggy_happy
                    Mood.WORRIED -> R.drawable.piggy_worried
                    Mood.SAD -> R.drawable.piggy_sad
                }
            )
            setTextViewText(R.id.streak, "🔥 $streak")
            setTextViewText(R.id.title, title)
            setTextViewText(R.id.message, message)

            if (wide) {
                setTextViewText(R.id.today_spent, if (hide) "••••" else todaySpent.ifEmpty { "—" })
                if (hasBudget) {
                    setViewVisibility(R.id.budget_block, View.VISIBLE)
                    setViewVisibility(R.id.no_budget, View.GONE)
                    setTextViewText(R.id.budget_left, if (hide) "••••" else s("bb_budget_left"))
                    setProgressBar(
                        R.id.budget_progress, 100,
                        (pct.coerceIn(0.0, 1.0) * 100).toInt(), false
                    )
                } else {
                    setViewVisibility(R.id.budget_block, View.GONE)
                    setViewVisibility(R.id.no_budget, View.VISIBLE)
                }
                setOnClickPendingIntent(R.id.widget_root, homeIntent)
                setOnClickPendingIntent(R.id.add_button, addIntent)
            } else {
                setOnClickPendingIntent(R.id.widget_root, addIntent)
            }
        }
    }
}
