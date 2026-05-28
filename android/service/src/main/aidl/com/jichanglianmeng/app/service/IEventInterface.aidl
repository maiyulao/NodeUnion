// IEventInterface.aidl
package com.jichanglianmeng.app.service;

import com.jichanglianmeng.app.service.IAckInterface;

interface IEventInterface {
    oneway void onEvent(in String id, in byte[] data,in boolean isSuccess, in IAckInterface ack);
}