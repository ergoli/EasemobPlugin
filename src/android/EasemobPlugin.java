package com.tyrion.plugin.easemob;

import android.annotation.TargetApi;
import android.content.Context;
import android.content.Intent;
import android.os.Build;
import android.util.Log;
import com.easemob.EMCallBack;
import com.easemob.EMConnectionListener;
import com.easemob.EMError;
import com.easemob.EMEventListener;
import com.easemob.EMNotifierEvent;
import com.easemob.chat.EMChat;
import com.easemob.chat.EMChatManager;
import com.easemob.chat.EMConversation;
import com.easemob.chat.EMGroupManager;
import com.easemob.chat.EMMessage;
import com.easemob.easeui.controller.EaseUI.EaseSettingsProvider;
import com.easemob.easeui.controller.EaseUI;
import com.easemob.util.NetUtils;

import org.apache.cordova.CordovaPlugin;
import org.apache.cordova.CallbackContext;
import org.apache.cordova.PluginResult;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

/**
 * This class echoes a string called from JavaScript.
 */
public class EasemobPlugin extends CordovaPlugin implements EMEventListener, EaseSettingsProvider, EMConnectionListener {

    private static EasemobPlugin instance;
    CallbackContext callback;
    static String currentChatID = "";
    public Context context = null;
    private MyEaseNotifier notifier;
    public EasemobPlugin() {
        instance = this;
    }

    public interface MessageType {
        int login_successed = 0;        //登录成功消息
        int login_failed = 1;           //登录失败消息
        int received_msg = 2;           //接收一条消息
        int joinedGroup = 3;            //加入群聊
        int leavedGroup_BeRemoved = 4;  //被管理员移除出该群组
        int leavedGroup_UserLeave = 5;  //用户主动退出该群组
        int leavedGroup_Destroyed = 6;  //该群组被别人销毁
        int loginFromOtherDevice = 7;   //在其他设备上登录成功,强制下线
        int stateGoSetting = 8;//跳转到聊天设置页面
        int clearRedDotWithConversationID = 9;//根据会话ID,清空该会话列表上对应红点
        int clearAllConversationRedDot = 10;//清空会话列表上所有红点
        int clickNotification = 11; //点击通知栏通知
    }

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
            EMChatManager.getInstance().addConnectionListener(this);//监听链接状态，用于检查是否异地登录

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
            String chatID = EMMessageUtil.getChatID(message);

            //##新消息-JS监听数据
            JSONObject msgJson = new JSONObject();
            try {
                msgJson.put("messageType", MessageType.received_msg);

                JSONObject msgData = new JSONObject();
                msgData.put("chat_id", chatID);
                msgData.put("title", EMMessageUtil.getMsgContent(message));
                msgData.put("timestamp", message.getMsgTime());
                msgData.put("unread_count", EMMessageUtil.getUnreadCount(message));

                msgJson.put("messageData", msgData);
            } catch (JSONException e) {
                e.printStackTrace();
            }
            EasemobPlugin.transmit("receiveEasemobMessage", msgJson);

            //非当前会话则弹出通知
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


    static void transmit(String methodName, JSONObject data) {
        if (instance == null) {
            return;
        }
        String js = String.format("window.plugins.easemobPlugin.%sInAndroidCallback('%s');", methodName, data.toString());
        instance.sendJavascript(js);
    }

    @TargetApi(Build.VERSION_CODES.KITKAT)
    private void sendJavascript(final String javascript) {
        webView.getRootView().post(new Runnable() {
            @Override
            public void run() {
                try {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT) {
                        webView.sendJavascript(javascript);
                    } else {
                        webView.loadUrl("javascript:" + javascript);
                    }
                } catch (Exception e) {
                    e.printStackTrace();
                }

             }
        });
    }

    @Override
    public void onConnected() {

    }

    @Override
    public void onDisconnected(int error) {
        if(error == EMError.USER_REMOVED){
            Log.e("onDisconnected", "显示帐号已经被移除");
        }else if (error == EMError.CONNECTION_CONFLICT) {
            Log.e("onDisconnected", "显示帐号在其他设备登陆");

            //##新消息-JS监听数据
            JSONObject msgJson = new JSONObject();
            try {
                msgJson.put("messageType", MessageType.loginFromOtherDevice);
            } catch (JSONException e) {
                e.printStackTrace();
            }
            EasemobPlugin.transmit("receiveEasemobMessage", msgJson);
        } else {
            if (NetUtils.hasNetwork(context)){
                Log.e("onDisconnected", "连接不到聊天服务器");
            }else {
                Log.e("onDisconnected", "当前网络不可用，请检查网络设置");
            }
        }
    }
}
