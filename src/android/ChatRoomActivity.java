package com.tyrion.plugin.easemob;

import android.content.Intent;
import android.os.Bundle;
import android.support.v4.app.FragmentActivity;
import android.util.Log;

import com.easemob.EMConnectionListener;
import com.easemob.EMError;
import com.easemob.chat.EMChatManager;
import com.easemob.chat.EMChatOptions;
import com.easemob.easeui.EaseConstant;
import com.easemob.easeui.controller.EaseUI;
import com.easemob.easeui.domain.EaseUser;
import com.easemob.easeui.ui.EaseChatFragment;
import com.easemob.util.NetUtils;
import com.evicord.panart.R;

import org.json.JSONException;
import org.json.JSONObject;

/**
 * Created by Tyrion on 16/2/19.
 */
public class ChatRoomActivity extends FragmentActivity implements EMConnectionListener {

    JSONObject usersJson = null;
    String groupID = "";
    String serverID = "";
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        // TODO Auto-generated method stub
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_chat);

        EMChatManager.getInstance().addConnectionListener(this);//监听链接状态，用于检查是否异地登录

        Intent intent=getIntent();
        groupID = intent.getStringExtra("groupID");
        serverID = intent.getStringExtra("serverID");
        final String usersList =intent.getStringExtra("usersList");
//        Log.e("groupID", groupID);

        EaseUI easeUI = EaseUI.getInstance();

        try {
            usersJson = new JSONObject(usersList);
        } catch (JSONException e) {
            e.printStackTrace();
        }

        //设置头像和昵称
        easeUI.setUserProfileProvider(new EaseUI.EaseUserProfileProvider() {

            @Override
            public EaseUser getUser(String username) {
            EaseUser user = new EaseUser(username);
            try {
//                Log.e(usersJson.getJSONObject(username).getString("nickname"), username);
                user.setNick(usersJson.getJSONObject(username).getString("nickname"));
                user.setAvatar(usersJson.getJSONObject(username).getString("avatar"));
            } catch (Exception e) {
                e.printStackTrace();
            }
            return user;
            }
        });

        EaseChatFragment chatFragment = new EaseChatFragment();
        Bundle args = new Bundle();
        args.putInt(EaseConstant.EXTRA_CHAT_TYPE, EaseConstant.CHATTYPE_GROUP);
        args.putString(EaseConstant.EXTRA_USER_ID, groupID);
        args.putString(EaseConstant.EXTRA_SERVER_ID, serverID);
        chatFragment.setArguments(args);
        getSupportFragmentManager().beginTransaction().add(R.id.container, chatFragment).commit();
    }

    @Override
    public void onDestroy() {
        super.onDestroy();
    }

    @Override
    public void onPause() {
        super.onPause();
        EasemobPlugin.currentChatID = "";
    }

    @Override
    public void onResume() {
        super.onResume();
        EasemobPlugin.currentChatID = groupID;
    }

    @Override
    public void onConnected() {

    }

    @Override
    public void onDisconnected(int error) {
        if (error == EMError.CONNECTION_CONFLICT) {
            ChatRoomActivity.this.finish();
        }
    }
}
