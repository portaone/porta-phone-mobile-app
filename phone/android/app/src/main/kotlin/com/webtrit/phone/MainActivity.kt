package com.webtrit.phone

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    /**
     * Answers whether the display is round. Flutter has no way to ask: a round watch face and a
     * square one are both a square window to it, and watch screens are laid out differently on
     * each. Configuration.isScreenRound has existed since API 23, below the app's minimum.
     */
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SCREEN_SHAPE_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "isScreenRound" -> result.success(resources.configuration.isScreenRound)
                else -> result.notImplemented()
            }
        }
    }

    /**
     * Overrides the default back-press behavior when Flutter's navigation stack is fully exhausted.
     *
     * By default, [FlutterActivity] calls [finish] at this point, which destroys the Activity and
     * tears down the Flutter engine — including any active WebRTC peer connections. This causes
     * in-progress calls to drop immediately.
     *
     * This override intentionally minimizes the app for **all** cases (not only during active calls).
     * This is the standard VoIP app pattern: the app maintains background signaling connections and
     * must stay alive to receive incoming calls, so "exit via Back" is replaced with "move to
     * background". Users can still fully close the app through the recent-apps screen.
     *
     * Falls back to [super.popSystemNavigator] if [moveTaskToBack] reports that the task could not
     * be moved (e.g. the activity is not part of a root task), preserving correct behavior in that
     * edge case.
     */
    override fun popSystemNavigator(): Boolean {
        return if (moveTaskToBack(true)) true else super.popSystemNavigator()
    }

    private companion object {
        const val SCREEN_SHAPE_CHANNEL = "com.webtrit.phone/screen_shape"
    }
}
