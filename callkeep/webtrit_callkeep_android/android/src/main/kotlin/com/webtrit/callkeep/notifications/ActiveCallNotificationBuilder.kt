package com.webtrit.callkeep.notifications

import android.app.Notification
import android.app.PendingIntent
import android.content.Intent
import android.graphics.drawable.Icon
import com.webtrit.callkeep.R
import com.webtrit.callkeep.common.ContextHolder.context
import com.webtrit.callkeep.managers.NotificationChannelManager
import com.webtrit.callkeep.managers.NotificationChannelManager.ACTIVE_CALL_SERVICE_NOTIFICATION_CHANNEL_ID
import com.webtrit.callkeep.models.CallConnectionState
import com.webtrit.callkeep.models.CallMetadata
import com.webtrit.callkeep.models.NotificationAction
import com.webtrit.callkeep.services.services.active_call.ActiveCallService

class ActiveCallNotificationBuilder : NotificationBuilder() {
    private var callsMetaData: List<CallMetadata> = emptyList()

    fun setCallsMetaData(callsMetaData: List<CallMetadata>) {
        this.callsMetaData = callsMetaData
    }

    override fun build(): Notification {
        // A single outgoing call that the other side has not answered yet - its metadata says
        // DIALING - is shown as an outgoing call rather than as an active one; several calls are
        // always "active calls".
        val title =
            when {
                callsMetaData.size > 1 -> {
                    context.getString(R.string.push_notification_active_calls_channel_title)
                }

                callsMetaData.singleOrNull()?.connectionState == CallConnectionState.DIALING -> {
                    context.getString(R.string.push_notification_outgoing_call_title)
                }

                else -> {
                    context.getString(R.string.push_notification_active_call_channel_title)
                }
            }

        val text = callsMetaData.joinToString { it.name ?: context.getString(R.string.unknown_caller) }

        val hungUpAction: Notification.Action =
            Notification.Action
                .Builder(
                    Icon.createWithResource(context, R.drawable.ic_call_hungup),
                    context.getString(R.string.hang_up_button_text),
                    getHungUpCallIntent(callsMetaData.firstOrNull()),
                ).build()

        val notificationBuilder =
            NotificationChannelManager
                .notificationBuilder(
                    context,
                    ACTIVE_CALL_SERVICE_NOTIFICATION_CHANNEL_ID,
                ).apply {
                    setSmallIcon(R.drawable.ic_notification)
                    setOngoing(true)
                    setOnlyAlertOnce(true)
                    setContentTitle(title)
                    setContentText(text)
                    setAutoCancel(false)
                    setCategory(Notification.CATEGORY_SERVICE)
                    setGroup(NOTIFICATION_GROUP_KEY)
                    setStyle(Notification.MediaStyle().setShowActionsInCompactView(0))
                    addAction(hungUpAction)
                }

        return notificationBuilder.build()
    }

    private fun getHungUpCallIntent(callMetaData: CallMetadata?): PendingIntent {
        val hangUpIntent =
            Intent(context, ActiveCallService::class.java).apply {
                action = NotificationAction.Decline.action
                callMetaData?.toBundle()?.let { putExtras(it) }
            }
        return PendingIntent.getService(
            context,
            0,
            hangUpIntent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )
    }

    companion object {
        const val TAG = "ACTIVE_CALL_NOTIFICATION"
        const val NOTIFICATION_ID = 1
        const val NOTIFICATION_GROUP_KEY = "com.webtrit.callkeep.ACTIVE_CALL"
    }
}
