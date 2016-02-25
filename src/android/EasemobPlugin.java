package com.tyrion.plugin.easemob;

import android.app.NotificationManager;
import android.content.Context;
import android.content.Intent;
import android.util.Log;
import com.easemob.EMCallBack;
import com.easemob.EMEventListener;
import com.easemob.EMNotifierEvent;
import com.easemob.chat.EMChat;
import com.easemob.chat.EMChatManager;
import com.easemob.chat.EMConversation;
import com.easemob.chat.EMGroupManager;
import com.easemob.chat.EMMessage;
import com.easemob.easeui.controller.EaseUI.EaseSettingsProvider;
import com.easemob.easeui.controller.EaseUI;
import org.apache.cordova.CordovaPlugin;
import org.apache.cordova.CallbackContext;
import org.apache.cordova.PluginResult;
import org.apache.cordova.dialogs.Notification;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

/**
 * This class echoes a string called from JavaScript.
 */
public class EasemobPlugin extends CordovaPlugin implements EMEventListener, EaseSettingsProvider{

    CallbackContext callback;
    static String currentChatID = "";
    public Context context = null;
    private MyEaseNotifier notifier;
    @Override
    public boolean execute(String action, JSONArray args, CallbackContext callbackContext) throws JSONException {
        if (action.equals("init")) {
            callback = callbackContext;
            context = this.cordova.getActivity();
            //环信和EaseUI初始化
            EMChat.getInstance().init(this.cordova.getActivity().getApplication());
            EMChat.getInstance().setDebugMode(true);
            EaseUI.getInstance().init(this.cordova.getActivity().getApplication());

            EMChatManager.getInstance().registerEventListener(this);//监听新消息，弹出顶部通知
            EaseUI.getInstance().setSettingsProvider(this);//设置震动和铃声

            notifier = new MyEaseNotifier(context);

            PluginResult result = new PluginResult(PluginResult.Status.OK, "init");
            callback.sendPluginResult(result);

            return true;
        }

        if (action.equals("login")) {
            callback = callbackContext;

            String userName = args.getString(0);
            String password = args.getString(1);

            EMChatManager.getInstance().login(userName, password, new EMCallBack() {//回调
                @Override
                public void onSuccess() {
                    EMGroupManager.getInstance().loadAllGroups();
                    EMChatManager.getInstance().loadAllConversations();
//                    Log.e("onSuccess", "登陆聊天服务器成功！");
                }

                @Override
                public void onProgress(int progress, String status) {
                    Log.e("onProgress", "progress:"+progress);
                }

                @Override
                public void onError(int code, String message) {
                    Log.e("onError", "登陆聊天服务器失败,code=" + code + ",message=" + message);
                }
            });
            PluginResult result = new PluginResult(PluginResult.Status.OK, "userName: " + userName + "/" + "password: " + password);
            callback.sendPluginResult(result);

            return true;
        }

        if (action.equals("chat")) {
            callback = callbackContext;

            Intent intent = new Intent();
            intent.setClass(this.cordova.getActivity(), SingleChatActivity.class);
            this.cordova.getActivity().startActivity(intent);

            PluginResult result = new PluginResult(PluginResult.Status.OK, "chat");
            callback.sendPluginResult(result);

            return true;
        }

        if (action.equals("chatRoom")) {
            callback = callbackContext;

            String groupID = args.getString(0);
            String usersList = args.getString(1);

            Log.e("groupID", groupID);
            Log.e("usersList", usersList);

            Intent intent = new Intent();
            intent.putExtra("groupID", groupID);
            intent.putExtra("usersList", usersList);
            intent.setClass(this.cordova.getActivity(), ChatRoomActivity.class);
            this.cordova.getActivity().startActivity(intent);

            currentChatID = groupID;

            PluginResult result = new PluginResult(PluginResult.Status.OK, "chat");
            callback.sendPluginResult(result);

            return true;
        }

        if(action.equals("getLatestMessage")){
            callback = callbackContext;
            JSONArray groupID = args.getJSONArray(0);

            JSONArray lastMsgs = new JSONArray();
            for(int i=0; i<groupID.length(); i++){
                JSONObject lastMsg = new JSONObject();
                String chatId = groupID.getString(i);

                EMConversation conversation = EMChatManager.getInstance().getConversation(chatId);
                int unreadMsgCount = conversation.getUnreadMsgCount();
                EMMessage message = conversation.getLastMessage();
                lastMsg.put("chat_id", chatId);
                lastMsg.put("unread_count", unreadMsgCount);
                lastMsg.put("title", EMMessageUtil.getMsgContent(message));
                lastMsg.put("timestamp", message.getMsgTime());
                lastMsgs.put(lastMsg);
            }

            PluginResult result = new PluginResult(PluginResult.Status.OK, lastMsgs);
            callback.sendPluginResult(result);
        }
        return false;
    }

    @Override
    public void onEvent(EMNotifierEvent event) {
        if(event.getEvent() == EMNotifierEvent.Event.EventNewMessage){
            EMMessage message = (EMMessage) event.getData();
//            Log.e("msg", message.getBody().toString());

            String chatID = message.getFrom();
            if (message.getChatType() == EMMessage.ChatType.GroupChat) {
                chatID = message.getTo();
            }

            if (!currentChatID.equals(chatID)) {
                notifier.onNewMsg(message);
            }
        }
    }

    @Override
    public boolean isMsgNotifyAllowed(EMMessage message) {
        return true;
    }

    @Override
    public boolean isMsgSoundAllowed(EMMessage message) {
        return false;
    }

    @Override
    public boolean isMsgVibrateAllowed(EMMessage message) {
        return true;
    }

    @Override
    public boolean isSpeakerOpened() {
        return true;
    }
}
