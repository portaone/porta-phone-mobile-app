package com.webtrit.callkeep

import android.content.Context
import android.content.pm.PackageManager
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import com.webtrit.callkeep.common.ActivityHolder
import com.webtrit.callkeep.common.BatteryModeHelper
import com.webtrit.callkeep.common.PermissionsHelper
import com.webtrit.callkeep.common.TelephonyUtils
import com.webtrit.callkeep.common.toAndroidPermissions
import com.webtrit.callkeep.common.toPPermissionResults
import io.flutter.plugin.common.PluginRegistry
import kotlinx.coroutines.CancellableContinuation
import kotlinx.coroutines.suspendCancellableCoroutine
import kotlinx.coroutines.withTimeoutOrNull
import java.util.concurrent.TimeoutException
import kotlin.coroutines.resume
import kotlin.coroutines.resumeWithException

class PermissionsApi(
    private val context: Context,
) : PHostPermissionsApi,
    PluginRegistry.RequestPermissionsResultListener {
    // The requestPermissions call that is waiting for the user's answer. One at a time:
    // Android delivers the result through onRequestPermissionsResult with no way to tell
    // two in-flight requests apart.
    private var pendingPermissionRequest: CancellableContinuation<List<PPermissionResult>>? = null

    override suspend fun getFullScreenIntentPermissionStatus(): PSpecialPermissionStatusTypeEnum {
        val screenIntentPermissionAvailable = PermissionsHelper(context).canUseFullScreenIntent()
        return if (screenIntentPermissionAvailable) PSpecialPermissionStatusTypeEnum.GRANTED else PSpecialPermissionStatusTypeEnum.DENIED
    }

    /**
     * Attempts to open the system settings screen for managing the "Use full screen intent" permission.
     *
     * This setting allows the app to show incoming call UI in full screen when the device is locked.
     * The method internally checks and starts the appropriate system intent.
     *
     * Throws (e.g., [android.content.ActivityNotFoundException]) if the intent cannot be handled;
     * pigeon reports the exception to Dart as a PlatformException.
     *
     * Note: This functionality is only supported on Android 13 (API 33) and above,
     * and may not be available on all devices even on supported versions.
     */
    override suspend fun openFullScreenIntentSettings() {
        PermissionsHelper(context).launchFullScreenIntentSettings()
    }

    /**
     * Reports the status of the OEM "display pop-up windows while running in
     * background" capability (MIUI/HyperOS), which gates showing the incoming
     * call UI over the lock screen. Best-effort; reports granted where the
     * capability does not apply.
     */
    override suspend fun getBackgroundActivityStartPermissionStatus(): PSpecialPermissionStatusTypeEnum =
        when (PermissionsHelper(context).isBackgroundActivityStartGranted()) {
            true -> PSpecialPermissionStatusTypeEnum.GRANTED
            false -> PSpecialPermissionStatusTypeEnum.DENIED
            null -> PSpecialPermissionStatusTypeEnum.UNKNOWN
        }

    /**
     * Opens the OEM permissions screen hosting the "display pop-up windows while
     * running in background" toggle, with a fallback to app settings.
     */
    override suspend fun openBackgroundActivityStartSettings() {
        PermissionsHelper(context).launchBackgroundActivityStartSettings()
    }

    /**
     * Reports the status of the OEM "show on lock screen" capability
     * (MIUI/HyperOS), which gates showing the incoming call UI over the lock
     * screen. Best-effort; reports granted where the capability does not apply.
     */
    override suspend fun getShowWhenLockedPermissionStatus(): PSpecialPermissionStatusTypeEnum =
        when (PermissionsHelper(context).isShowWhenLockedGranted()) {
            true -> PSpecialPermissionStatusTypeEnum.GRANTED
            false -> PSpecialPermissionStatusTypeEnum.DENIED
            null -> PSpecialPermissionStatusTypeEnum.UNKNOWN
        }

    /**
     * Opens the OEM permissions screen hosting the "show on lock screen"
     * toggle, with a fallback to app settings.
     */
    override suspend fun openShowWhenLockedSettings() {
        PermissionsHelper(context).launchShowWhenLockedSettings()
    }

    /**
     * Attempts to open the common system settings screen
     */
    override suspend fun openSettings() {
        PermissionsHelper(context).launchSettings()
    }

    override suspend fun getBatteryMode(): PCallkeepAndroidBatteryMode {
        val batteryMode = BatteryModeHelper(context)
        return when {
            batteryMode.isUnrestricted() -> PCallkeepAndroidBatteryMode.UNRESTRICTED
            batteryMode.isRestricted() -> PCallkeepAndroidBatteryMode.RESTRICTED
            batteryMode.isOptimized() -> PCallkeepAndroidBatteryMode.OPTIMIZED
            else -> PCallkeepAndroidBatteryMode.UNKNOWN
        }
    }

    /**
     * Reports whether incoming calls are delivered via the Telecom
     * [android.telecom.ConnectionService] path or the limited standalone
     * foreground-service path used when the device lacks
     * `android.software.telecom`. Mirrors the same feature gate the router uses,
     * so the value reflects the actually active delivery path.
     */
    override suspend fun getCallDeliveryMode(): PCallkeepAndroidCallDeliveryMode =
        if (TelephonyUtils.isTelecomSupported(context)) {
            PCallkeepAndroidCallDeliveryMode.TELECOM
        } else {
            PCallkeepAndroidCallDeliveryMode.STANDALONE
        }

    /**
     * Requests the given permissions from the user and suspends until the user answers,
     * the request times out, or it is cancelled.
     * @param permissions The list of permissions to request.
     * @return The result for every requested permission.
     */
    override suspend fun requestPermissions(permissions: List<PCallkeepPermission>): List<PPermissionResult> {
        val activity = ActivityHolder.getActivity() ?: throw IllegalStateException("No active Activity")

        val androidPerms = permissions.toAndroidPermissions()
        val missing =
            androidPerms.filter {
                ContextCompat.checkSelfPermission(context, it) != PackageManager.PERMISSION_GRANTED
            }

        if (missing.isEmpty()) {
            return androidPerms.toPPermissionResults(context)
        }

        return withTimeoutOrNull(PERMISSION_REQUEST_TIMEOUT_MS) {
            suspendCancellableCoroutine { continuation ->
                synchronized(this@PermissionsApi) {
                    if (pendingPermissionRequest != null) {
                        continuation.resumeWithException(IllegalStateException("A permission request is already in progress"))
                        return@suspendCancellableCoroutine
                    }
                    pendingPermissionRequest = continuation
                }
                continuation.invokeOnCancellation {
                    synchronized(this@PermissionsApi) {
                        if (pendingPermissionRequest === continuation) pendingPermissionRequest = null
                    }
                }

                try {
                    activity.runOnUiThread {
                        ActivityCompat.requestPermissions(
                            activity,
                            missing.toTypedArray(),
                            PERMISSION_REQUEST_CODE,
                        )
                    }
                } catch (e: Exception) {
                    synchronized(this@PermissionsApi) {
                        if (pendingPermissionRequest === continuation) pendingPermissionRequest = null
                    }
                    continuation.resumeWithException(e)
                }
            }
        } ?: throw TimeoutException("User did not accept/deny permissions within $PERMISSION_REQUEST_TIMEOUT_MS ms")
    }

    /**
     * Checks the current status of the given permissions without requesting them.
     * @param permissions The list of permissions to check.
     * @return The status of every given permission.
     */
    override suspend fun checkPermissionsStatus(permissions: List<PCallkeepPermission>): List<PPermissionResult> = permissions.toAndroidPermissions().toPPermissionResults(context)

    /**
     * Handles the result of a permission request.
     * This method is called by the Android system when the user responds to a permission request.
     */
    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ): Boolean {
        if (requestCode != PERMISSION_REQUEST_CODE) {
            return false
        }

        val continuation =
            synchronized(this) {
                val pending = pendingPermissionRequest ?: return false
                pendingPermissionRequest = null
                pending
            }
        if (!continuation.isActive) return true

        try {
            continuation.resume(permissions.toList().toPPermissionResults(context))
        } catch (e: Exception) {
            continuation.resumeWithException(e)
        }

        return true
    }

    companion object {
        private const val PERMISSION_REQUEST_CODE = 10101
        private const val PERMISSION_REQUEST_TIMEOUT_MS = 20_000L
    }
}
