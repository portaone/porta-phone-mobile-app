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
     * What each channel is worth, in one place.
     *
     * Registration reads it, and so does the pre-O path below, which has to say the same thing
     * on the notification itself. Kept as a table rather than repeated at both ends because the
     * two would otherwise drift silently: lowering a channel's importance would leave the older
     * releases loud, and a channel added without a row here would quietly come out as the least
     * important thing on the device.
     */
    private val channelImportance =
        mapOf(
            INCOMING_CALL_NOTIFICATION_CHANNEL_ID to NotificationManager.IMPORTANCE_HIGH,
            ACTIVE_CALL_SERVICE_NOTIFICATION_CHANNEL_ID to NotificationManager.IMPORTANCE_LOW,
            FOREGROUND_CALL_NOTIFICATION_CHANNEL_ID to NotificationManager.IMPORTANCE_LOW,
        )

    /** Channels that carry no tone of their own, because the app plays one. */
    private val silentChannels = setOf(INCOMING_CALL_NOTIFICATION_CHANNEL_ID)

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
     * channel, and the channels are declared just above: with nothing to read the channel from,
     * its importance has to travel on the notification as a priority and its silence has to be
     * said again.
     *
     * What the degradation does not reproduce is the peek. On API 26+ an `IMPORTANCE_HIGH`
     * channel heads up whether or not it makes a sound; below O the platform peeks only for a
     * notification that is noisy or carries a full-screen intent, and the incoming-call channel
     * is deliberately silent so the app can ring its own tone. The incoming call therefore
     * heads up on API 24-25 through its full-screen intent, which is set whenever the in-app
     * setting allows it - and with that setting off it will sit in the shade instead of taking
     * the screen. Worth confirming on a device before the floor drops.
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
            setPriority(legacyPriorityOf(channelId))
            if (channelId in silentChannels) {
                setSound(null)
                setDefaults(0)
            }
        }
    }

    /** The pre-O priority that stands for a channel's importance. */
    @Suppress("DEPRECATION")
    private fun legacyPriorityOf(channelId: String): Int =
        when (channelImportance[channelId] ?: NotificationManager.IMPORTANCE_DEFAULT) {
            NotificationManager.IMPORTANCE_MAX -> Notification.PRIORITY_MAX
            NotificationManager.IMPORTANCE_HIGH -> Notification.PRIORITY_HIGH
            NotificationManager.IMPORTANCE_LOW -> Notification.PRIORITY_LOW
            NotificationManager.IMPORTANCE_MIN -> Notification.PRIORITY_MIN
            else -> Notification.PRIORITY_DEFAULT
        }

    /**
     * Registers all necessary notification channels.
     *
     * This method calls the individual methods to register channels for active calls,
     * incoming calls, missed calls, and foreground calls.
     *
     * @param context The context used to access system services and resources.
     */
    private fun importanceOf(channelId: String): Int = requireNotNull(channelImportance[channelId]) { "no importance declared for channel $channelId" }

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
            importance = importanceOf(ACTIVE_CALL_SERVICE_NOTIFICATION_CHANNEL_ID),
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
            importance = importanceOf(INCOMING_CALL_NOTIFICATION_CHANNEL_ID),
            lockscreenVisibility = Notification.VISIBILITY_PUBLIC,
            customSound = INCOMING_CALL_NOTIFICATION_CHANNEL_ID in silentChannels,
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
            importance = importanceOf(FOREGROUND_CALL_NOTIFICATION_CHANNEL_ID),
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
        // NotificationChannel is an API 26 class, so merely constructing one throws
        // NoClassDefFoundError below that - in Service.onCreate, before a single notification is
        // built. NotificationManagerCompat.createNotificationChannel already no-ops on old
        // releases; the object has to be skipped too, and there is nothing to register anyway,
        // because what a channel would have carried travels on the notification instead.
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return

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
