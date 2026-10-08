package com.webtrit.callkeep.common

import android.media.Ringtone
import android.os.Build
import org.junit.Test
import org.junit.runner.RunWith
import org.mockito.Mockito.mock
import org.mockito.Mockito.verify
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

/**
 * [setLoopingCompat] has to turn looping on for every supported Android version. Below API 28
 * `Ringtone.setLooping` is hidden, and a ringtone that is not told to loop plays its file once
 * and leaves a still-ringing call silent (WT-2080).
 *
 * Each test runs against the framework classes of the versions it names, so a version whose
 * `Ringtone` has no such method fails here.
 */
@RunWith(RobolectricTestRunner::class)
class RingtoneLoopingCompatTest {
    @Test
    @Config(
        sdk = [
            Build.VERSION_CODES.N,
            Build.VERSION_CODES.N_MR1,
            Build.VERSION_CODES.O,
            Build.VERSION_CODES.O_MR1,
        ],
    )
    fun `turns looping on below API 28, where the method is hidden`() {
        val ringtone = mock(Ringtone::class.java)

        ringtone.setLoopingCompat(true)

        verify(ringtone).isLooping = true
    }

    @Test
    @Config(sdk = [Build.VERSION_CODES.P, Build.VERSION_CODES.UPSIDE_DOWN_CAKE])
    fun `turns looping on from API 28, where the method is public`() {
        val ringtone = mock(Ringtone::class.java)

        ringtone.setLoopingCompat(true)

        verify(ringtone).isLooping = true
    }
}
