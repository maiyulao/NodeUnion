package com.jichanglianmeng.app.service.models

import android.os.Parcelable
import kotlinx.parcelize.Parcelize

@Parcelize
data class NotificationParams(
    val title: String = "",
    val stopText: String = "STOP",
    val onlyStatisticsProxy: Boolean = false,
) : Parcelable