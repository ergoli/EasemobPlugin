//
//  EasemobPlugin.h
//  泛艺术
//
//  Created by zsly on 16/2/22.
//
//

#import <Cordova/CDV.h>
#import "EaseMob.h"

typedef enum _messageType
{
    login_successed,//登录成功消息
    login_failed,//登录失败消息
    received_msg,//接收一条消息,绘制消息红点,如果路由在会话列表页面绘制对应红点
    joinedGroup,//加入群聊
    leavedGroup_BeRemoved,//被管理员移除出该群组,如果路由在会话列表页面删除对应会话
    leavedGroup_UserLeave,//用户主动退出该群组,如果路由在会话列表页面删除对应会话
    leavedGroup_Destroyed,//该群组被别人销毁,如果路由在会话列表页面删除对应会话
    loginFromOtherDevice,//在其他设备上登录成功,强制下线
    stateGoSetting,//跳转到聊天设置页面
    clearRedDotWithConversationID,//根据会话ID,清空该会话列表上对应红点
    clearAllConversationRedDot,//清空会话列表上所有红点}MessageType;
}MessageType;


static NSString *networkDidReceiveMessageFromIM=@"networkDidReceiveMessageFromIM";
static NSString *sendMsgToWebView=@"sendMsgToWebView";
static void *conversationIDKey = &conversationIDKey;
@interface EasemobPlugin : CDVPlugin

/*环信异步登陆*/
-(void)login:(CDVInvokedUrlCommand*)command;

/*环信异步登出*/
-(void)logOut:(CDVInvokedUrlCommand*)command;

/*根据数组id获取环信会话信息*/
-(void)getLatestMessage:(CDVInvokedUrlCommand*)command;

-(void)chat:(CDVInvokedUrlCommand*)command;

-(void)chatRoom:(CDVInvokedUrlCommand*)command;

+(NSString*)getMessageTitle:(EMMessage *)message;
@end
