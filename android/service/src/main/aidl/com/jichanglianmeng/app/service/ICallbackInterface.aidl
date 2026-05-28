// ICallbackInterface.aidl
package com.jichanglianmeng.app.service;

import com.jichanglianmeng.app.service.IAckInterface;

interface ICallbackInterface {
    oneway void onResult(in byte[] data,in boolean isSuccess, in IAckInterface ack);
}