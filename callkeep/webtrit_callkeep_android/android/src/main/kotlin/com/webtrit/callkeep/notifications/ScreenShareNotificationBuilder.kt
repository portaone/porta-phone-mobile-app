package com.webtrit.callkeep.notifications

import android.app.Notification
import android.app.PendingIntent
import android.content.Intent
import android.graphics.drawable.Icon
import com.webtrit.callkeep.R
import com.webtrit.callkeep.common.ContextHolder.context
import com.webtrit.callkeep.managers.NotificationChannelManager
import com.webtrit.callkeep.managers.NotificationChannelManager.SCREEN_SHARE_NOTIFICATION_CHANNEL_ID
import com.webtrit.callkeep.services.services.screen_share.ScreenShareService

/**
 * The notification of [ScreenShareService]: says the screen is being shown to the other side of the
 * call and offers to stop it from the shade, where the person is likely to be while sharing - the
 * app is behind whatever is being shown.
 */
class ScreenShareNotificationBuilder : NotificationBuilder() {
    override fun build(): Notification {
        val stopAction =
            Notification.Action
                .Builder(
                    Icon.createWithResource(context, R.drawable.ic_call_hungup),
                    context.getString(R.string.screen_share_stop_button_text),
                    stopIntent(),
                ).build()

        return NotificationChannelManager
            .notificationBuilder(context, SCREEN_SHARE_NOTIFICATION_CHANNEL_ID)
            .apply {
                setSmallIcon(R.drawable.ic_notification)
                setOngoing(true)
                setOnlyAlertOnce(true)
                setContentTitle(context.getString(R.string.screen_share_notification_title))
                setContentText(context.getString(R.string.screen_share_notification_text))
                setContentIntent(buildOpenAppIntent(context))
                setAutoCancel(false)
                setCategory(Notification.CATEGORY_SERVICE)
                addAction(stopAction)
            }.build()
    }

    private fun stopIntent(): PendingIntent =
        PendingIntent.getService(
            context,
            0,
            Intent(context, ScreenShareService::class.java).setAction(ScreenShareService.ACTION_STOP),
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )

    companion object {
        const val NOTIFICATION_ID = 98
    }
}
