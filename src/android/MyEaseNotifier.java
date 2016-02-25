package com.tyrion.plugin.easemob;

import android.content.Context;
import android.content.Intent;
import android.content.pm.PackageManager;

import com.easemob.EMNotifierEvent;
import com.easemob.chat.EMChatManager;
import com.easemob.chat.EMGroup;
import com.easemob.chat.EMGroupManager;
import com.easemob.chat.EMMessage;
import com.easemob.easeui.controller.EaseUI;
import com.easemob.easeui.model.EaseNotifier;

/**
 * Created by Tyrion on 16/2/25.
 */
public class MyEaseNotifier extends EaseNotifier {

    public static final String NOTIFIER_CLICK = "com.tyrion.notifier.event";
    public MyEaseNotifier(final Context context) {
        init(context);
        this.setNotificationInfoProvider(new EaseNotificationInfoProvider() {
            @Override
            public String getDisplayedText(EMMessage message) {
                return getNotifierContent(message);
            }

            @Override
            public String getLatestText(EMMessage message, int fromUsersNum, int messageNum) {
                return getNotifierContent(message);
            }

            @Override
            public String getTitle(EMMessage message) {
                PackageManager packageManager = appContext.getPackageManager();
                String appname = (String) packageManager.getApplicationLabel(appContext.getApplicationInfo());
                return appname;
            }

            @Override
            public int getSmallIcon(EMMessage message) {
                return 0;
            }

            @Override
            public Intent getLaunchIntent(EMMessage message) {

                Intent intent = new Intent(NOTIFIER_CLICK);
                intent.putExtra("msg", message);
                return intent;
            }
        });
    }

    private String getNotifierContent(EMMessage message){
        String chatID = message.getFrom();
        String name;
        if (message.getChatType() == EMMessage.ChatType.GroupChat) {
            chatID = message.getTo();
            EMGroup group = EMGroupManager.getInstance().getGroup(chatID);
            if (group != null){
                name = group.getGroupName();
            }else{
                name = "群组";
            }
        }else{
            //处理单聊的昵称
            name = "好友";
        }
        return name + ":" + EMMessageUtil.getMsgContent(message);
    }

    @Override
    public synchronized void onNewMsg(EMMessage message) {
        if(EMChatManager.getInstance().isSlientMessage(message)){
            return;
        }
        EaseUI.EaseSettingsProvider settingsProvider = EaseUI.getInstance().getSettingsProvider();
        if(!settingsProvider.isMsgNotifyAllowed(message)){
            return;
        }

        sendNotification(message, false);

        viberateAndPlayTone(message);
    }
}
