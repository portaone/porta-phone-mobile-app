package com.webtrit.callkeep

import android.content.Context
import com.webtrit.callkeep.common.CallDiagnostics

class DiagnosticsApi(
    private val context: Context,
) : PHostDiagnosticsApi {
    override suspend fun getDiagnosticReport(): Map<String, Any?> = CallDiagnostics.gatherMap(context)
}
