package com.jichanglianmeng.app.models

import com.jichanglianmeng.app.service.models.VpnOptions
import com.google.gson.annotations.SerializedName

data class SharedState(
    val startTip: String = "Starting VPN...",
    val stopTip: String = "Stopping VPN...",
    val crashlytics: Boolean = true,
    val currentProfileName: String = "机场联盟",
    val stopText: String = "Stop",
    val onlyStatisticsProxy: Boolean = false,
    val vpnOptions: VpnOptions? = null,
    val setupParams: SetupParams? = null,
)

data class SetupParams(
    @SerializedName("test-url")
    val testUrl: String,
    @SerializedName("selected-map")
    val selectedMap: Map<String, String>,
)
