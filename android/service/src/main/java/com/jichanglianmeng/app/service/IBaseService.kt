package com.jichanglianmeng.app.service

import com.jichanglianmeng.app.common.BroadcastAction
import com.jichanglianmeng.app.common.GlobalState
import com.jichanglianmeng.app.common.sendBroadcast

interface IBaseService {
    fun handleCreate() {
        GlobalState.log("Service create")
        BroadcastAction.SERVICE_CREATED.sendBroadcast()
    }

    fun handleDestroy() {
        GlobalState.log("Service destroy")
        BroadcastAction.SERVICE_DESTROYED.sendBroadcast()
    }

    fun start()

    fun stop()
}