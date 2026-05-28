package com.jichanglianmeng.app.service

import android.content.Intent
import com.jichanglianmeng.app.common.ServiceDelegate
import com.jichanglianmeng.app.service.models.NotificationParams
import com.jichanglianmeng.app.service.models.VpnOptions
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.sync.Mutex

object State {
    var options: VpnOptions? = null
    var notificationParamsFlow: MutableStateFlow<NotificationParams?> = MutableStateFlow(
        NotificationParams()
    )

    val runLock = Mutex()
    var runTime: Long = 0L

    var delegate: ServiceDelegate<IBaseService>? = null

    var intent: Intent? = null
}