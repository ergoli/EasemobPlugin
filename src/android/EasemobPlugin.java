package com.tyrion.plugin.easemob;

import android.content.Intent;
import android.util.Log;

import com.easemob.EMCallBack;
import com.easemob.chat.EMChat;
import com.easemob.chat.EMChatManager;
import com.easemob.chat.EMConversation;
import com.easemob.chat.EMMessage;
import com.easemob.chat.MessageBody;
import com.easemob.easeui.controller.EaseUI;
import com.tyrion.plugin.easemob.SingleChatActivity;
import com.tyrion.plugin.easemob.ChatRoomActivity;

import org.apache.cordova.CordovaPlugin;
import org.apache.cordova.CallbackContext;

import org.apache.cordova.PluginResult;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

/**
 * This class echoes a string called from JavaScript.
 */
public class EasemobPlugin extends CordovaPlugin {

    CallbackContext callback;

    @Override
    public boolean execute(String action, JSONArray args, CallbackContext callbackContext) throws JSONException {
        if (action.equals("init")) {
            callback = callbackContext;

            EMChat.getInstance().init(this.cordova.getActivity().getApplication());
            EMChat.getInstance().setDebugMode(true);

            EaseUI.getInstance().init(this.cordova.getActivity().getApplication());

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
//                    runOnUiThread(new Runnable() {
//                        public void run() {
//                            EMGroupManager.getInstance().loadAllGroups();
//                            EMChatManager.getInstance().loadAllConversations();
//                            Log.e("main", "登陆聊天服务器成功！");
//                        }
//                    });

                    Log.e("onSuccess", "登陆聊天服务器成功！");

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
                String msgBody = message.getBody().toString();
                String msgTitle = msgBody.substring(msgBody.indexOf(":"), msgBody.length());

                lastMsg.put("chat_id", chatId);
                lastMsg.put("unread_count", unreadMsgCount);
                if (message.getType() == EMMessage.Type.TXT) {
                    lastMsg.put("title", msgTitle);
                } else if (message.getType() == EMMessage.Type.IMAGE) {
                    lastMsg.put("title", "[图片]");
                } else if (message.getType() == EMMessage.Type.LOCATION) {
                    lastMsg.put("title", "[位置]");
                } else if (message.getType() == EMMessage.Type.VOICE) {
                    lastMsg.put("title", "[语音]");
                } else if (message.getType() == EMMessage.Type.VIDEO) {
                    lastMsg.put("title", "[视频]");
                } else if (message.getType() == EMMessage.Type.FILE) {
                    lastMsg.put("title", "[文件]");
                }
                lastMsg.put("timestamp", message.getMsgTime());
                lastMsgs.put(lastMsg);
            }

            PluginResult result = new PluginResult(PluginResult.Status.OK, lastMsgs);
            callback.sendPluginResult(result);
        }
        return false;
    }
}
