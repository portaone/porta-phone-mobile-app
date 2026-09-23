package com.webtrit.callkeep.notifications

import android.app.Notification
import android.app.PendingIntent
import android.app.Person
import android.content.Intent
import android.graphics.drawable.Icon
import android.os.Build
import androidx.core.app.NotificationCompat
import com.webtrit.callkeep.R
import com.webtrit.callkeep.common.CallDataConst
import com.webtrit.callkeep.common.ContextHolder.context
import com.webtrit.callkeep.managers.NotificationChannelManager
import com.webtrit.callkeep.managers.NotificationChannelManager.ACTIVE_CALL_SERVICE_NOTIFICATION_CHANNEL_ID
import com.webtrit.callkeep.models.CallMetadata
import com.webtrit.callkeep.services.services.connection.StandaloneCallService
import com.webtrit.callkeep.services.services.connection.StandaloneServiceAction

/**
 * Builds the ongoing (answered) call notification for the standalone call path - the path taken
 * wherever Telecom cannot host our calls: no [android.software.telecom] feature, or a release
 * below API 26, where a self-managed `PhoneAccount` cannot be registered.
 *
 * Counterpart of [StandaloneIncomingCallNotificationBuilder]: once a call is answered or
 * established, [StandaloneCallService] replaces its foreground incoming-call notification (which
 * still carries Answer/Decline actions) with this one, mirroring the Telecom path where the
 * incoming notification is cancelled on answer and an active-call notification is posted.
 * The Hang up action is routed directly to [StandaloneCallService] via
 * [StandaloneServiceAction.HungUpCall]; tapping the notification body opens the app.
 */
internal class StandaloneActiveCallNotificationBuilder : NotificationBuilder() {
    private var callMetaData: CallMetadata? = null
    private var groupMembers: List<CallMetadata> = emptyList()

    fun setCallMetaData(callMetaData: CallMetadata) {
        this.callMetaData = callMetaData
    }

    /**
     * The calls grouped with this one, this call included, or empty when it stands alone.
     *
     * A group is shown as a single ongoing call naming everyone in it, rather than as one entry
     * per call: there is one notification id on this path, so per-call entries would overwrite
     * each other and leave whichever call was answered last standing for the whole group.
     */
    fun setGroupMembers(groupMembers: List<CallMetadata>) {
        this.groupMembers = groupMembers
    }

    private fun createHangUpIntent(metadata: CallMetadata): PendingIntent {
        val intent =
            Intent(context, StandaloneCallService::class.java).apply {
                action = StandaloneServiceAction.HungUpCall.action
                putExtras(metadata.toBundle())
            }
        return PendingIntent.getService(
            context,
            // Same request-code scheme as StandaloneIncomingCallNotificationBuilder.createActionIntent:
            // the action ordinal keeps this PendingIntent distinct from the Answer/Decline ones.
            StandaloneServiceAction.HungUpCall.ordinal,
            intent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )
    }

    /**
     * Hang up for a grouped notification ends every call in the group.
     *
     * The notification stands for the group, so its one button has to mean what it appears to
     * mean. Ending a single leg from a control that names several people would be a lie, and the
     * user has no way to pick which leg it was.
     */
    private fun createHangUpGroupIntent(members: List<CallMetadata>): PendingIntent {
        val intent =
            Intent(context, StandaloneCallService::class.java).apply {
                action = StandaloneServiceAction.HungUpCallGroup.action
                putExtra(CallDataConst.CALL_IDS, members.map { it.callId }.toTypedArray())
            }
        return PendingIntent.getService(
            context,
            StandaloneServiceAction.HungUpCallGroup.ordinal,
            intent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )
    }

    override fun build(): Notification {
        val meta =
            requireNotNull(callMetaData) { "Call metadata must be set before building the notification." }

        val isGrouped = groupMembers.size >= 2
        val callerName = notificationName(meta, groupMembers, context.getString(R.string.unknown_caller))
        val hangUpIntent = if (isGrouped) createHangUpGroupIntent(groupMembers) else createHangUpIntent(meta)

        val builder =
            NotificationChannelManager.notificationBuilder(context, ACTIVE_CALL_SERVICE_NOTIFICATION_CHANNEL_ID).apply {
                setSmallIcon(if (meta.hasVideo == true) R.drawable.ic_notification_video else R.drawable.ic_notification)
                setCategory(NotificationCompat.CATEGORY_CALL)
                setContentTitle(context.getString(R.string.push_notification_active_call_channel_title))
                setContentText(callerName)
                setOngoing(true)
                setAutoCancel(false)
                setOnlyAlertOnce(true)
                setContentIntent(buildOpenAppIntent(context))
            }

        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val person =
                Person
                    .Builder()
                    .setName(callerName)
                    .setImportant(true)
                    .build()
            builder
                .setStyle(Notification.CallStyle.forOngoingCall(person, hangUpIntent))
                .build()
        } else {
            builder
                .addAction(
                    Notification.Action
                        .Builder(
                            Icon.createWithResource(context, R.drawable.ic_call_hungup),
                            context.getString(R.string.hang_up_button_text),
                            hangUpIntent,
                        ).build(),
                ).build()
        }
    }

    internal companion object {
        /**
         * The name the ongoing-call notification shows: the caller, or everyone in the group.
         *
         * Names are joined rather than counted, so the notification says who is in the room.
         * Deliberately not a new string resource - a list of names reads the same in every
         * language, whereas "and 2 others" would need translating and says less.
         *
         * A group needs two calls, so a list of one is treated as no group at all, which is the
         * same floor the service applies when it assigns calls to groups.
         */
        internal fun notificationName(
            call: CallMetadata,
            groupMembers: List<CallMetadata>,
            unknownCaller: String,
        ): String =
            if (groupMembers.size >= 2) {
                groupMembers.joinToString { it.name ?: unknownCaller }
            } else {
                call.name ?: unknownCaller
            }
    }
}
