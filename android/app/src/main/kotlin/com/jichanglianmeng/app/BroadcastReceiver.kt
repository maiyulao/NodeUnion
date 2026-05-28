package com.jichanglianmeng.app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import com.jichanglianmeng.app.common.BroadcastAction
import com.jichanglianmeng.app.common.GlobalState
import com.jichanglianmeng.app.common.action
import kotlinx.coroutines.launch

class BroadcastReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context?, intent: Intent?) {
        when (intent?.action) {
            BroadcastAction.SERVICE_CREATED.action -> {
                GlobalState.log("Receiver service created")
                GlobalState.launch {
                    State.handleStartServiceAction()
                }
            }

            BroadcastAction.SERVICE_DESTROYED.action -> {
                GlobalState.log("Receiver service destroyed")
                GlobalState.launch {
                    State.handleStopServiceAction()
                }
            }
        }
    }
}