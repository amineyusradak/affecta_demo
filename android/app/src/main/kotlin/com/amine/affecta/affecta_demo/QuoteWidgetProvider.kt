package com.amine.affecta.affecta_demo

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider
import java.util.Calendar

/**
 * Ana ekran widget'ı: günün sözünü gösterir.
 *
 * Uygulama önümüzdeki 7 günün sözlerini "quote_2026-10-14" gibi anahtarlarla kaydeder.
 * Widget her yenilendiğinde bugünün anahtarını okur; böylece uygulama
 * açılmasa bile gece yarısından sonra yeni günün sözüne geçer.
 */
class QuoteWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        val c = Calendar.getInstance()
        val today = "${c.get(Calendar.YEAR)}-${c.get(Calendar.MONTH) + 1}-${c.get(Calendar.DAY_OF_MONTH)}"

        val quote = widgetData.getString("quote_$today", null)
            ?: widgetData.getString("quote_latest", null)
        val author = widgetData.getString("author_$today", null)
            ?: widgetData.getString("author_latest", null)

        appWidgetIds.forEach { id ->
            val views = RemoteViews(context.packageName, R.layout.quote_widget).apply {
                if (quote != null) setTextViewText(R.id.widget_quote, "“$quote”")

                if (author.isNullOrEmpty()) {
                    setViewVisibility(R.id.widget_author, View.GONE)
                } else {
                    setViewVisibility(R.id.widget_author, View.VISIBLE)
                    setTextViewText(R.id.widget_author, "— $author")
                }

                // Dokununca uygulamayı aç
                setOnClickPendingIntent(
                    R.id.widget_root,
                    HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java),
                )
            }
            appWidgetManager.updateAppWidget(id, views)
        }
    }
}
