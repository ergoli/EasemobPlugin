package com.tyrion.plugin.easemob;

import com.easemob.chat.EMMessage;
import org.json.JSONException;
import org.json.JSONObject;

/**
 * Created by Tyrion on 16/2/25.
 */
public class EMMessageUtil {
    public static String getMsgContent(EMMessage message){
        String msgBody = message.getBody().toString();
        String msgContent = "有一条新消息";
        if (message.getType() == EMMessage.Type.TXT) {
            msgContent = msgBody.substring(msgBody.indexOf(":"), msgBody.length());
            try {
                JSONObject msgBodyObj = new JSONObject("{" + msgBody + "}");
                msgContent = msgBodyObj.getString("txt");
            } catch (JSONException e) {
                e.printStackTrace();
            }
        } else if (message.getType() == EMMessage.Type.IMAGE) {
            msgContent = "[图片]";
        } else if (message.getType() == EMMessage.Type.LOCATION) {
            msgContent = "[位置]";
        } else if (message.getType() == EMMessage.Type.VOICE) {
            msgContent = "[语音]";
        } else if (message.getType() == EMMessage.Type.VIDEO) {
            msgContent = "[视频]";
        } else if (message.getType() == EMMessage.Type.FILE) {
            msgContent = "[文件]";
        }
        return msgContent;
    }

    public static String getChatID(EMMessage message){
        String chatID = message.getFrom();
        if (message.getChatType() == EMMessage.ChatType.GroupChat) {
            chatID = message.getTo();
        }
        return chatID;
    }
}
