package com.webtrit.callkeep.managers

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.os.Build
import androidx.core.app.NotificationManagerCompat
import com.webtrit.callkeep.R

/**
 * Singleton that manages the creation and registration of notification channels.
 */
object NotificationChannelManager {
    // Constants for notification channel IDs
    const val INCOMING_CALL_NOTIFICATION_CHANNEL_ID = "INCOMING_CALL_NOTIFICATION_CHANNEL_ID"
    const val FOREGROUND_CALL_NOTIFICATION_CHANNEL_ID = "FOREGROUND_CALL_NOTIFICATION_CHANNEL_ID"
    const val ACTIVE_CALL_SERVICE_NOTIFICATION_CHANNEL_ID = "ACTIVE_CALL_SERVICE_NOTIFICATION_CHANNEL"

    /**
     * A notification builder bound to [channelId] on every supported API level.
     *
     * Channels arrived in API 26, and so did the two-argument [Notification.Builder]
     * constructor that names one. Below that only `Notification.Builder(Context)` exists, so
     * calling the channel constructor unconditionally is a `NoSuchMethodError` on API 24-25 -
     * thrown for every notification this plugin posts, which on the standalone path means an
     * incoming call that never appears.
     *
     * It lives here rather than among the generic extensions because what it does is degrade a
     * channel, and the channels are declared a few lines above: with nothing to read the
     * channel from, its importance has to travel on the notification as a priority, and the
     * incoming-call channel's silence - it is registered with `setSound(null, null)` so the app
     * can ring itself - has to be said again. Without that an incoming call on API 24-25 would
     * arrive as an ordinary, silent, flat line in the shade.
     */
    @Suppress("DEPRECATION")
    fun notificationBuilder(
        context: Context,
        channelId: String,
    ): Notification.Builder {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            return Notification.Builder(context, channelId)
        }
        return Notification.Builder(context).apply {
            when (channelId) {
                INCOMING_CALL_NOTIFICATION_CHANNEL_ID -> {
                    setPriority(Notification.PRIORITY_HIGH)
                    setSound(null)
                    setDefaults(0)
                }

                else -> {
                    setPriority(Notification.PRIORITY_LOW)
                }
            }
        }
    }

    /**
     * Registers all necessary notification channels.
     *
     * This method calls the individual methods to register channels for active calls,
     * incoming calls, missed calls, and foreground calls.
     *
     * @param context The context used to access system services and resources.
     */
    fun registerNotificationChannels(context: Context) {
        NotificationManagerCompat.from(context).deleteNotificationChannel("NOTIFICATION_ACTIVE_CALL_CHANNEL_ID")
        registerActiveCallChannel(context)
        registerIncomingCallChannel(context)
        registerForegroundCallChannel(context)
    }

    /**
     * Registers the notification channel for active calls.
     *
     * This channel is used for notifications related to ongoing calls.
     *
     * @param context The context used to access system services and resources.
     */
    private fun registerActiveCallChannel(context: Context) {
        registerNotificationChannel(
            context,
            channelId = ACTIVE_CALL_SERVICE_NOTIFICATION_CHANNEL_ID,
            title = context.getString(R.string.push_notification_active_call_channel_title),
            description = context.getString(R.string.push_notification_active_call_channel_description),
            importance = NotificationManager.IMPORTANCE_LOW,
        )
    }

    /**
     * Registers the notification channel for incoming calls.
     *
     * This channel is used for notifications related to incoming calls with a high priority.
     *
     * @param context The context used to access system services and resources.
     */
    private fun registerIncomingCallChannel(context: Context) {
        registerNotificationChannel(
            context,
            channelId = INCOMING_CALL_NOTIFICATION_CHANNEL_ID,
            title = context.getString(R.string.push_notification_incoming_call_channel_title),
            description = context.getString(R.string.push_notification_incoming_call_channel_description),
            importance = NotificationManager.IMPORTANCE_HIGH,
            lockscreenVisibility = Notification.VISIBILITY_PUBLIC,
            customSound = true,
            showBadge = true,
        )
    }

    /**
     * Registers the notification channel for foreground calls.
     *
     * This channel is used for notifications related to calls running in the foreground.
     *
     * @param context The context used to access system services and resources.
     */
    private fun registerForegroundCallChannel(context: Context) {
        registerNotificationChannel(
            context,
            channelId = FOREGROUND_CALL_NOTIFICATION_CHANNEL_ID,
            title = context.getString(R.string.push_notification_foreground_call_service_title),
            description = context.getString(R.string.push_notification_foreground_call_service_description),
            importance = NotificationManager.IMPORTANCE_LOW,
        )
    }

    /**
     * Registers a notification channel with the provided parameters.
     *
     * @param channelId The ID of the notification channel.
     * @param title The title of the notification channel.
     * @param description A brief description of the notification channel's purpose.
     * @param importance The importance level of the notification channel.
     * @param showBadge Whether the channel should show a badge (default is true).
     * @param customSound Whether the channel should use a custom sound (default is false).
     * @param lockscreenVisibility The visibility of the notification on the lockscreen (default is public).
     */
    private fun registerNotificationChannel(
        context: Context,
        channelId: String,
        title: String,
        description: String,
        importance: Int,
        showBadge: Boolean = true,
        customSound: Boolean = false,
        lockscreenVisibility: Int = Notification.VISIBILITY_PUBLIC,
    ) {
        val notificationChannel =
            NotificationChannel(
                channelId,
                title,
                importance,
            ).apply {
                this.description = description
                this.lockscreenVisibility = lockscreenVisibility
                setShowBadge(showBadge)
                if (customSound) setSound(null, null)
            }
        NotificationManagerCompat
            .from(context)
            .createNotificationChannel(notificationChannel)
    }
}
