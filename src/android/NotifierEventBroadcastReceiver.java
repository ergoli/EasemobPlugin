package com.tyrion.plugin.easemob;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.util.Log;

import com.easemob.chat.EMMessage;

import org.json.JSONException;
import org.json.JSONObject;

import java.util.HashMap;
import java.util.Map;

import cn.jpush.android.api.JPushInterface;

/**
 * Created by Tyrion on 16/2/25.
 */
public class NotifierEventBroadcastReceiver extends BroadcastReceiver{
    @Override
    public void onReceive(Context context, Intent intent) {
        EMMessage message = intent.getParcelableExtra("msg");
        Log.e("onReceive", EMMessageUtil.getMsgContent(message));
        //##点击消息栏通知
        JSONObject msgJson = new JSONObject();
        try {
            msgJson.put("messageType", EasemobPlugin.MessageType.clickNotification);

            JSONObject msgData = new JSONObject();
            msgData.put("chat_id", EMMessageUtil.getChatID(message));
            msgData.put("title", EMMessageUtil.getMsgContent(message));
            msgData.put("timestamp", message.getMsgTime());
            msgData.put("unread_count", EMMessageUtil.getUnreadCount(message));

            msgJson.put("messageData", msgData);
        } catch (JSONException e) {
            e.printStackTrace();
        }
        EasemobPlugin.transmit("receiveEasemobMessage", msgJson);
    }
}
