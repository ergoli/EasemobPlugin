package com.tyrion.plugin.easemob;

import android.content.Intent;
import android.os.Bundle;
import android.support.v4.app.FragmentActivity;
import android.util.Log;

import com.easemob.easeui.EaseConstant;
import com.easemob.easeui.controller.EaseUI;
import com.easemob.easeui.domain.EaseUser;
import com.easemob.easeui.ui.EaseChatFragment;
import com.evicord.panart.R;

import org.json.JSONException;
import org.json.JSONObject;

/**
 * Created by Tyrion on 16/2/19.
 */
public class ChatRoomActivity extends FragmentActivity{

    JSONObject usersJson = null;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        // TODO Auto-generated method stub
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_chat);

        Intent intent=getIntent();
        String groupID =intent.getStringExtra("groupID");
        final String usersList =intent.getStringExtra("usersList");
        Log.e("groupID", groupID);

        EaseUI.getInstance().init(this.getApplication());
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
                    user.setNick(usersJson.getJSONObject(username).getString("nickname"));
                    user.setAvatar(usersJson.getJSONObject(username).getString("avatar"));
                } catch (JSONException e) {
                    e.printStackTrace();
                }
                return user;
            }
        });

        EaseChatFragment chatFragment = new EaseChatFragment();
        Bundle args = new Bundle();
        args.putInt(EaseConstant.EXTRA_CHAT_TYPE, EaseConstant.CHATTYPE_GROUP);
        args.putString(EaseConstant.EXTRA_USER_ID, groupID);
        chatFragment.setArguments(args);
        getSupportFragmentManager().beginTransaction().add(R.id.container, chatFragment).commit();
    }
}
