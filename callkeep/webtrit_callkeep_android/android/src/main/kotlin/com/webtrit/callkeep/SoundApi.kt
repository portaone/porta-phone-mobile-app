package com.webtrit.callkeep

import android.content.Context
import com.webtrit.callkeep.common.StorageDelegate
import com.webtrit.callkeep.managers.AudioManager

class SoundApi(
    private val context: Context,
) : PHostSoundApi {
    private val audioManager = AudioManager(context)

    override suspend fun playRingbackSound() {
        val assetPath = StorageDelegate.Sound.getRingbackPath(context)
        if (assetPath != null) audioManager.startRingback(assetPath)
    }

    override suspend fun stopRingbackSound() {
        audioManager.stopRingback()
    }
}
