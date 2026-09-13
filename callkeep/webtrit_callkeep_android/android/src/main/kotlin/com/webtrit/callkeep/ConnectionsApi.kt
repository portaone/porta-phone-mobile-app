package com.webtrit.callkeep

import com.webtrit.callkeep.services.core.CallkeepCore

class ConnectionsApi : PHostConnectionsApi {
    private val core: CallkeepCore = CallkeepCore.instance

    override suspend fun getConnection(callId: String): PCallkeepConnection? = core.toPCallkeepConnection(callId)

    override suspend fun getConnections(): List<PCallkeepConnection> =
        core
            .getAll()
            .mapNotNull { core.toPCallkeepConnection(it.callId) }

    override suspend fun cleanConnections() {
        // Clear the shadow state and send CleanConnections command to :callkeep_core.
        // PhoneConnectionService handles it by calling connectionManager.cleanConnections()
        // on its own heap, which is safe cross-process after the split.
        core.clear()
        core.sendCleanConnections()
    }
}
