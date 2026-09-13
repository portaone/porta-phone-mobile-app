package com.webtrit.callkeep

import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.ServiceConnection
import android.os.IBinder
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.LifecycleEventObserver
import androidx.lifecycle.LifecycleOwner
import com.webtrit.callkeep.common.ActivityHolder
import com.webtrit.callkeep.common.AssetCacheManager
import com.webtrit.callkeep.common.ContextHolder
import com.webtrit.callkeep.common.Log
import com.webtrit.callkeep.common.setShowWhenLockedCompat
import com.webtrit.callkeep.common.setTurnScreenOnCompat
import com.webtrit.callkeep.services.broadcaster.ActivityLifecycleState
import com.webtrit.callkeep.services.core.CallkeepCore
import com.webtrit.callkeep.services.services.foreground.ForegroundService
import com.webtrit.callkeep.services.services.incoming_call.IncomingCallService
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.embedding.engine.plugins.lifecycle.HiddenLifecycleReference
import io.flutter.embedding.engine.plugins.service.ServiceAware
import io.flutter.embedding.engine.plugins.service.ServicePluginBinding
import io.flutter.plugin.common.BinaryMessenger

/** WebtritCallkeepAndroidPlugin */
class WebtritCallkeepPlugin :
    FlutterPlugin,
    ActivityAware,
    ServiceAware,
    LifecycleEventObserver {
    private var activityPluginBinding: ActivityPluginBinding? = null
    private var lifeCycle: Lifecycle? = null

    private lateinit var messenger: BinaryMessenger
    private lateinit var context: Context

    private var pushNotificationIsolateService: IncomingCallService? = null

    private var foregroundService: ForegroundService? = null
    private var serviceConnection: ServiceConnection? = null

    // Registered as the PHostApi handler on activity attach and told when the service binds
    // and unbinds; see ForegroundServiceProxy for what happens to a call in between.
    private val serviceProxy = ForegroundServiceProxy()

    private var permissionsApi: PermissionsApi? = null

    // The BinaryMessenger that belongs to the Activity's Flutter engine, captured
    // synchronously in onAttachedToActivity BEFORE bindForegroundService() runs.
    //
    // WebtritCallkeepPlugin.messenger is a shared mutable field overwritten by every
    // onAttachedToEngine() call. Push-notification isolates (IncomingCallService) each
    // run in their own FlutterEngine and trigger onAttachedToEngine() independently.
    // If a push isolate's onAttachedToEngine fires BETWEEN onAttachedToActivity() and
    // the async onServiceConnected() callback, messenger will be pointing to the push
    // engine's BinaryMessenger when flutterDelegateApi is created — causing
    // performAnswerCall to be sent to the wrong engine where it is silently dropped.
    // Capturing the Activity's messenger here, before any async gap, prevents this race.
    private var activityBinaryMessenger: BinaryMessenger? = null

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        // Store binnyMessenger for later use if instance of the flutter engine belongs to main isolate OR call service isolate
        messenger = flutterPluginBinding.binaryMessenger
        context = flutterPluginBinding.applicationContext

        ContextHolder.init(context)
        AssetCacheManager.init(context)

        // Bootstrap isolate APIs
        BackgroundPushNotificationIsolateBootstrapApi(context).let {
            PHostBackgroundPushNotificationIsolateBootstrapApi.setUp(messenger, it)
        }
        SmsReceptionConfigBootstrapApi(context).let {
            PHostSmsReceptionConfigApi.setUp(messenger, it)
        }

        // Helper APIs

        permissionsApi = PermissionsApi(context)
        permissionsApi?.let {
            PHostPermissionsApi.setUp(messenger, it)
        }

        Log.i(TAG, "onAttachedToEngine id:${flutterPluginBinding.hashCode()}")

        DiagnosticsApi(context).let {
            PHostDiagnosticsApi.setUp(messenger, it)
        }

        SoundApi(context).let {
            PHostSoundApi.setUp(messenger, it)
        }
        ConnectionsApi().let {
            PHostConnectionsApi.setUp(messenger, it)
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        Log.i(TAG, "onDetachedFromEngine id:${binding.hashCode()}")

        PHostPermissionsApi.setUp(messenger, null)
        permissionsApi = null

        PHostApi.setUp(this.messenger, null)

        PHostBackgroundPushNotificationIsolateBootstrapApi.setUp(messenger, null)

        PHostDiagnosticsApi.setUp(messenger, null)
        PHostSoundApi.setUp(messenger, null)
        PHostConnectionsApi.setUp(messenger, null)
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        Log.i(TAG, "onAttachedToActivity id:${binding.hashCode()}")
        this.activityPluginBinding = binding
        // Capture Activity's messenger before bindForegroundService() to prevent the race
        // where a push-isolate onAttachedToEngine() overwrites messenger before
        // onServiceConnected() fires and reads it to create flutterDelegateApi.
        activityBinaryMessenger = messenger

        ActivityHolder.setActivity(binding.activity)

        ActivityControlApi(binding.activity).let {
            PHostActivityControlApi.setUp(messenger, it)
        }

        permissionsApi?.let {
            binding.addRequestPermissionsResultListener(it)
        }

        val lifecycle = (binding.lifecycle as HiddenLifecycleReference).lifecycle
        lifeCycle = lifecycle
        lifecycle.addObserver(this)

        // Register the proxy immediately so setUp() calls from Dart are never lost
        // during the asynchronous bindService() window.
        PHostApi.setUp(messenger, serviceProxy)

        bindForegroundService(binding.activity)
    }

    override fun onDetachedFromActivity() {
        Log.i(TAG, "onDetachedFromActivity id:${activityPluginBinding?.hashCode()}")
        activityBinaryMessenger = null
        ActivityHolder.setActivity(null)

        permissionsApi?.let {
            activityPluginBinding?.removeRequestPermissionsResultListener(it)
        }

        this.lifeCycle?.removeObserver(this)

        activityPluginBinding?.activity?.let { unbindAndStopForegroundService(it) }
        PHostApi.setUp(messenger, null)
        PHostActivityControlApi.setUp(messenger, null)

        foregroundService = null
        serviceConnection = null
    }

    override fun onAttachedToService(binding: ServicePluginBinding) {
        Log.i(TAG, "onAttachedToService id:${binding.hashCode()}")
        // Create communication bridge between the service and the push notification isolate
        if (binding.service is IncomingCallService) {
            Log.i(TAG, "IncomingCallService detected, setting up communication bridge")
            pushNotificationIsolateService = binding.service as? IncomingCallService

            pushNotificationIsolateService?.establishFlutterCommunication(
                PDelegateBackgroundServiceFlutterApi(messenger),
                PDelegateBackgroundRegisterFlutterApi(messenger),
            )

            PHostBackgroundPushNotificationIsolateApi.setUp(
                messenger,
                pushNotificationIsolateService?.getCallLifecycleHandler(),
            )
        }
    }

    override fun onDetachedFromService() {
        Log.i(TAG, "onDetachedFromService id:${activityPluginBinding?.hashCode()}")
        PHostBackgroundPushNotificationIsolateApi.setUp(messenger, null)

        pushNotificationIsolateService = null
    }

    override fun onDetachedFromActivityForConfigChanges() {
        Log.i(TAG, "onDetachedFromActivityForConfigChanges id:${activityPluginBinding?.hashCode()}")
        this.lifeCycle?.removeObserver(this)
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        Log.i(TAG, "onReattachedToActivityForConfigChanges id:${binding.hashCode()}")
        val lifecycle = (binding.lifecycle as HiddenLifecycleReference).lifecycle
        lifeCycle = lifecycle
        lifecycle.addObserver(this)
    }

    override fun onStateChanged(
        source: LifecycleOwner,
        event: Lifecycle.Event,
    ) {
        Log.d(
            TAG,
            "onStateChanged: Lifecycle event received - $event, activity: ${activityPluginBinding?.activity}",
        )
        ActivityLifecycleState.setValue(event)

        /*
         * This block is essential for the incoming call flow on the lock screen.
         *
         * It manages the `setShowWhenLocked` and `setTurnScreenOn` permissions
         * to reliably show the Activity. On modern Android versions,
         * the `setFullScreenIntent` alone is often not enough to wake the
         * device and show the Activity; these flags are required.
         *
         * We set these flags here programmatically *only when a call is active*,
         * rather than in the `AndroidManifest.xml`. If set in the Manifest,
         * the Activity would *always* attempt to show on the lock screen,
         * which is not the desired behavior.
         *
         * `ON_START` is our only reliable "checkpoint" that fires every
         * time the Activity becomes visible. This logic handles two scenarios:
         *
         * 1. (Activate) If the Activity starts *during* an active call,
         * `hasActiveConnections` will be `true`, and we force
         * the Activity over the lock screen and turn the screen on.
         *
         * 2. (Clear) If the Activity starts *after* a call has
         * ended (or the user is just opening the app normally),
         * `hasActiveConnections` will be `false`. This guarantees
         * that we clear the flags.
         *
         * We don't use `ON_STOP` for clearing because, on some devices,
         * it's called almost immediately after `ON_START` on the lock screen,
         * which leads to a race condition (setting flags to `true` then
         * immediately to `false`). This `ON_START`-only approach also solves
         * the problem where flags could get "stuck" in `true` (e.g., if
         * the app was force-stopped).
         */
        if (event == Lifecycle.Event.ON_START) {
            val core = CallkeepCore.instance
            val promoted = core.getAll()
            // Also check pending calls to cover the broadcast-lag window: CS may have
            // created a PhoneConnection and be about to send IncomingConnectionReported, but the
            // core shadow has not yet promoted the call. Without this check, ON_START during
            // that window would incorrectly clear the lock-screen and turn-screen-on flags.
            val hasActiveConnections = promoted.isNotEmpty() || core.getPendingCallIds().isNotEmpty()
            Log.i(
                TAG,
                "onStateChanged: ON_START. Has active connections: $hasActiveConnections" +
                    " (promoted=${promoted.size}, pending=${core.getPendingCallIds().size})",
            )
            activityPluginBinding?.activity?.setShowWhenLockedCompat(hasActiveConnections)
            activityPluginBinding?.activity?.setTurnScreenOnCompat(hasActiveConnections)
        }
    }

    private fun bindForegroundService(activity: Context) {
        val intent = Intent(activity, ForegroundService::class.java)
        val foregroundServiceConnection =
            object : ServiceConnection {
                override fun onServiceConnected(
                    name: ComponentName?,
                    service: IBinder?,
                ) {
                    Log.i(TAG, "ForegroundService connected: ${service?.javaClass?.name}")
                    val binder = service as ForegroundService.LocalBinder
                    foregroundService = binder.getService()
                    // Use activityBinaryMessenger (captured synchronously in onAttachedToActivity)
                    // rather than the shared messenger field which may have been overwritten by a
                    // push-isolate engine that started after onAttachedToActivity but before this
                    // async callback fired.
                    foregroundService?.flutterDelegateApi = PDelegateFlutterApi(activityBinaryMessenger ?: messenger)
                    // Replay any setUp() call that arrived before the service connected.
                    foregroundService?.let { serviceProxy.connected(it) }
                }

                override fun onServiceDisconnected(name: ComponentName?) {
                    Log.w(TAG, "ForegroundService disconnected")
                    foregroundService = null
                    serviceProxy.disconnected()
                }
            }
        serviceConnection = foregroundServiceConnection
        activity.bindService(intent, foregroundServiceConnection, Context.BIND_AUTO_CREATE)
    }

    private fun unbindAndStopForegroundService(activity: Context) {
        serviceConnection?.let { conn ->
            try {
                activity.unbindService(conn)
                val stopIntent = Intent(activity, ForegroundService::class.java)
                activity.stopService(stopIntent)
                Log.i(TAG, "unbindAndStopForegroundService: ForegroundService unbound and stopped")
            } catch (e: IllegalArgumentException) {
                Log.e(TAG, "unbindAndStopForegroundService: Service not registered - ${e.message}")
            }
        }

        serviceConnection = null
        foregroundService = null
        serviceProxy.disconnected()
        PHostApi.setUp(messenger, null)
    }

    companion object {
        const val TAG = "WebtritCallkeepPlugin"
    }
}
