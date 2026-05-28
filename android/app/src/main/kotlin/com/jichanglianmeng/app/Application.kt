package com.jichanglianmeng.app

import android.app.Application
import android.content.Context
import com.jichanglianmeng.app.common.GlobalState

class Application : Application() {

    override fun attachBaseContext(base: Context?) {
        super.attachBaseContext(base)
        GlobalState.init(this)
    }
}
