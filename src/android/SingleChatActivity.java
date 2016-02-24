package com.tyrion.plugin.easemob;

import android.content.Intent;
import android.os.Bundle;
import android.support.v4.app.FragmentActivity;
import android.util.Log;
import android.view.MotionEvent;
import android.view.View;

import com.easemob.easeui.EaseConstant;
import com.easemob.easeui.controller.EaseUI;
import com.easemob.easeui.domain.EaseEmojicon;
import com.easemob.easeui.domain.EaseUser;
import com.easemob.easeui.model.EaseVoiceRecorder;
import com.easemob.easeui.ui.EaseChatFragment;
import com.easemob.easeui.utils.EaseUserUtils;
import com.easemob.easeui.widget.EaseChatInputMenu;
import com.easemob.easeui.widget.EaseVoiceRecorderView;
import com.evicord.panart.R;

/**
 * Created by Tyrion on 16/2/19.
 */
public class SingleChatActivity extends FragmentActivity{

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        // TODO Auto-generated method stub
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_chat);

        Intent intent=getIntent();
        String call_id =intent.getStringExtra("call_id");
        String call_name =intent.getStringExtra("call_name");

        Log.e("call_id", call_id);
        Log.e("call_name", call_name);

        EaseUI.getInstance().init(this.getApplication());
        EaseUI easeUI = EaseUI.getInstance();
        //需要easeui库显示用户头像和昵称设置此provider
        easeUI.setUserProfileProvider(new EaseUI.EaseUserProfileProvider() {

            @Override
            public EaseUser getUser(String username) {
                EaseUser user = null;
                if(username.equals("user_db2424abb67b4361ac9f2c635a908dcb")){
                    user = new EaseUser(username);
                    user.setNick("1@1.com");
                    user.setAvatar("https://www.baidu.com/img/bd_logo1.png");
                } else if (username.equals("user_e1a45f3b47344dbb87ad3963ab080601")){
                    user = new EaseUser(username);
                    user.setNick("13@1.com");
                    user.setAvatar("http://img1.touxiang.cn/uploads/20131103/03-034229_273.jpg");
                }
                return user;
            }
        });


        EaseChatFragment chatFragment = new EaseChatFragment();
        //传入参数
        Bundle args = new Bundle();
        args.putInt(EaseConstant.EXTRA_CHAT_TYPE, EaseConstant.CHATTYPE_SINGLE);
        args.putString(EaseConstant.EXTRA_USER_ID, call_id);
        chatFragment.setArguments(args);
        getSupportFragmentManager().beginTransaction().add(R.id.container, chatFragment).commit();

//        EaseChatInputMenu inputMenu = (EaseChatInputMenu)findViewById(R.id.input_menu);
////注册底部菜单扩展栏item
////传入item对应的文字，图片及点击事件监听，extendMenuItemClickListener实现EaseChatExtendMenuItemClickListener
//        inputMenu.registerExtendMenuItem(R.string.attach_video, R.drawable.em_chat_video_selector, ITEM_VIDEO, extendMenuItemClickListener);
//        inputMenu.registerExtendMenuItem(R.string.attach_file, R.drawable.em_chat_file_selector, ITEM_FILE, extendMenuItemClickListener);
//
////初始化，此操作需放在registerExtendMenuItem后
//        inputMenu.init();
////设置相关事件监听
//
//        final EaseVoiceRecorderView voiceRecorderView = (EaseVoiceRecorderView)findViewById(R.id.voice_recorder);
//        inputMenu.setChatInputMenuListener(new EaseChatInputMenu.ChatInputMenuListener() {
//
//            @Override
//            public void onSendMessage(String content) {
//                // 发送文本消息
//                Log.e("发送消息",content);
//            }
//
//            @Override
//            public void onBigExpressionClicked(EaseEmojicon emojicon) {
//
//            }
//
//            @Override
//            public boolean onPressToSpeakBtnTouch(View v, MotionEvent event) {
//                ////把touch事件传入到EaseVoiceRecorderView 里进行录音
//                return voiceRecorderView.onPressToSpeakBtnTouch(v, event, new EaseVoiceRecorderView.EaseVoiceRecorderCallback() {
//                    @Override
//                    public void onVoiceRecordComplete(String voiceFilePath, int voiceTimeLength) {
//                        // 发送语音消息
////                        sendVoiceMessage(voiceFilePath, voiceTimeLength);
//                        Log.e("发送语音", voiceFilePath+"  /  " + voiceTimeLength);
//                    }
//                });
//            }
//        });
    }
}
