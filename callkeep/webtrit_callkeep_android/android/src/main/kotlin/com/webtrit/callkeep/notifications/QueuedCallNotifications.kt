package com.webtrit.callkeep.notifications

import android.annotation.SuppressLint
import android.app.Notification
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.graphics.drawable.Icon
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import com.webtrit.callkeep.R
import com.webtrit.callkeep.activities.QueuedCallTrampolineActivity
import com.webtrit.callkeep.common.ContextHolder
import com.webtrit.callkeep.common.Log
import com.webtrit.callkeep.managers.NotificationChannelManager
import com.webtrit.callkeep.managers.NotificationChannelManager.QUEUED_CALL_NOTIFICATION_CHANNEL_ID
import com.webtrit.callkeep.models.CallMetadata
import com.webtrit.callkeep.services.core.QueuedCallNotifier
import com.webtrit.callkeep.services.receivers.QueuedCallActionReceiver

/**
 * The notification of a call waiting in the core's queue while another incoming call rings.
 *
 * Silent and low importance: it never heads up over the ringing call or over an open app, which
 * shows every call itself. Two actions, both carried out by the core so they work without a
 * running Flutter engine: Answer ends the ringing call and answers this one as soon as it rings,
 * Decline current ends the ringing call and lets the queue put the next call through.
 */
class QueuedCallNotifications(
    private val contextProvider: () -> Context = { ContextHolder.context },
) : QueuedCallNotifier {
    private val context get() = contextProvider()

    @SuppressLint("MissingPermission")
    override fun show(metadata: CallMetadata) {
        val notifier = NotificationManagerCompat.from(context)
        if (!notifier.areNotificationsEnabled()) {
            Log.w(TAG, "show: notifications are off, ${metadata.callId} waits without one")
            return
        }
        NotificationChannelManager.registerNotificationChannels(context)
        try {
            notifier.notify(notificationId(metadata.callId), QueuedCallNotificationBuilder(context, metadata).build())
        } catch (e: SecurityException) {
            Log.w(TAG, "show: notification refused for ${metadata.callId}", e)
        }
    }

    override fun cancel(callId: String) {
        NotificationManagerCompat.from(context).cancel(notificationId(callId))
    }

    companion object {
        private const val TAG = "QueuedCallNotifications"

        // Apart from the call's incoming notification id, which the same call takes once it rings.
        fun notificationId(callId: String): Int = IncomingCallNotificationBuilder.notificationId("queued:$callId")
    }
}

/** Builds the notification of one waiting call. */
class QueuedCallNotificationBuilder(
    private val context: Context,
    private val metadata: CallMetadata,
) : NotificationBuilder() {
    override fun build(): Notification {
        val content = incomingCallContent(metadata)
        val callId = metadata.callId
        val answer =
            PendingIntent.getActivity(
                context,
                QueuedCallNotifications.notificationId(callId),
                Intent(context, QueuedCallTrampolineActivity::class.java)
                    .putExtra(QueuedCallTrampolineActivity.EXTRA_CALL_ID, callId),
                PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
            )
        val declineRinging =
            PendingIntent.getBroadcast(
                context,
                QueuedCallNotifications.notificationId(callId) + 1,
                Intent(context, QueuedCallActionReceiver::class.java)
                    .setAction(QueuedCallActionReceiver.ACTION_DECLINE_RINGING),
                PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
            )
        return NotificationChannelManager
            .notificationBuilder(context, QUEUED_CALL_NOTIFICATION_CHANNEL_ID)
            .apply {
                setSmallIcon(content.smallIcon)
                setCategory(NotificationCompat.CATEGORY_CALL)
                setContentTitle(context.getString(R.string.queued_call_title))
                setContentText(context.getString(R.string.queued_call_description, content.callerName))
                setOngoing(true)
                setOnlyAlertOnce(true)
                setVisibility(Notification.VISIBILITY_PUBLIC)
                setContentIntent(buildOpenAppIntent(context))
                addAction(action(R.drawable.ic_call_hungup, R.string.queued_call_decline_ringing_button_text, declineRinging))
                addAction(action(R.drawable.ic_call_answer, R.string.queued_call_answer_button_text, answer))
            }.build()
    }

    private fun action(
        iconRes: Int,
        textRes: Int,
        intent: PendingIntent,
    ): Notification.Action =
        Notification.Action
            .Builder(Icon.createWithResource(context, iconRes), context.getString(textRes), intent)
            .build()
}
