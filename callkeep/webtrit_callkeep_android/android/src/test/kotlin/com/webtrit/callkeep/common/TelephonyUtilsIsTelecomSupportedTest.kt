package com.webtrit.callkeep.common

import android.content.Context
import android.os.Build
import android.telephony.TelephonyManager
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.RuntimeEnvironment
import org.robolectric.Shadows
import org.robolectric.annotation.Config

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [Build.VERSION_CODES.UPSIDE_DOWN_CAKE])
class TelephonyUtilsIsTelecomSupportedTest {
    private lateinit var context: Context

    @Before
    fun setUp() {
        context = RuntimeEnvironment.getApplication()
    }

    private fun setFeatureFlag(enabled: Boolean) {
        Shadows
            .shadowOf(context.packageManager)
            .setSystemFeature("android.software.telecom", enabled)
    }

    private fun setPhoneType(phoneType: Int) {
        Shadows
            .shadowOf(context.getSystemService(Context.TELEPHONY_SERVICE) as TelephonyManager)
            .setPhoneType(phoneType)
    }

    @Test
    fun `returns true when feature flag is present`() {
        setFeatureFlag(true)
        assertTrue(TelephonyUtils.isTelecomSupported(context))
    }

    @Test
    fun `returns true when feature flag is absent but phoneType is non-NONE`() {
        setFeatureFlag(false)
        setPhoneType(TelephonyManager.PHONE_TYPE_GSM)
        assertTrue(TelephonyUtils.isTelecomSupported(context))
    }

    @Test
    fun `returns false when feature flag is absent and phoneType is NONE`() {
        setFeatureFlag(false)
        setPhoneType(TelephonyManager.PHONE_TYPE_NONE)
        assertFalse(TelephonyUtils.isTelecomSupported(context))
    }

    @Test
    @Config(sdk = [Build.VERSION_CODES.N])
    fun `returns false below API 26 even when the feature flag is present`() {
        setFeatureFlag(true)

        // The flag branch would answer yes on its own. It is not reached: a self-managed
        // PhoneAccount cannot be registered here, so Telecom would take the call and lose it.
        assertFalse(TelephonyUtils.isTelecomSupported(context))
    }

    @Test
    @Config(sdk = [Build.VERSION_CODES.N_MR1])
    fun `returns false below API 26 on a phone the OEM fallback would accept`() {
        setFeatureFlag(false)
        setPhoneType(TelephonyManager.PHONE_TYPE_GSM)

        // This is the Android 7 handset the customer asked about: real telephony, so both
        // branches below would say yes, and both are wrong before self-managed exists.
        assertFalse(TelephonyUtils.isTelecomSupported(context))
    }

    @Test
    @Config(sdk = [Build.VERSION_CODES.O])
    fun `still answers the device from API 26 on`() {
        setFeatureFlag(true)

        assertTrue(TelephonyUtils.isTelecomSupported(context))
    }
}
