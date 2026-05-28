// IRemoteInterface.aidl
package com.jichanglianmeng.app.service;

import com.jichanglianmeng.app.service.ICallbackInterface;
import com.jichanglianmeng.app.service.IEventInterface;
import com.jichanglianmeng.app.service.IResultInterface;
import com.jichanglianmeng.app.service.IVoidInterface;
import com.jichanglianmeng.app.service.models.VpnOptions;
import com.jichanglianmeng.app.service.models.NotificationParams;

interface IRemoteInterface {
    void invokeAction(in String data, in ICallbackInterface callback);
    void quickSetup(in String initParamsString, in String setupParamsString, in ICallbackInterface callback, in IVoidInterface onStarted);
    void updateNotificationParams(in NotificationParams params);
    void startService(in VpnOptions options, in long runTime, in IResultInterface result);
    void stopService(in IResultInterface result);
    void setEventListener(in IEventInterface event);
    void setCrashlytics(in boolean enable);
    long getRunTime();
}