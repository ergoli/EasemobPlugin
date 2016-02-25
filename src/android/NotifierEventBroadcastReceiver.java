package com.tyrion.plugin.easemob;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.util.Log;

import com.easemob.chat.EMMessage;

/**
 * Created by Tyrion on 16/2/25.
 */
public class NotifierEventBroadcastReceiver extends BroadcastReceiver{
    @Override
    public void onReceive(Context context, Intent intent) {
        EMMessage message = intent.getParcelableExtra("msg");
        Log.e("onReceive", EMMessageUtil.getMsgContent(message));
    }
}
