/************************************************************
 *  * EaseMob CONFIDENTIAL
 * __________________
 * Copyright (C) 2013-2014 EaseMob Technologies. All rights reserved.
 *
 * NOTICE: All information contained herein is, and remains
 * the property of EaseMob Technologies.
 * Dissemination of this information or reproduction of this material
 * is strictly forbidden unless prior written permission is obtained
 * from EaseMob Technologies.
 */

#import "AppDelegate+EaseMob.h"
#import "EasemobPlugin.h"
#import "EaseUI.h"
#import "APService.h"
#import "TTGlobalUICommon.h"
#import "Utils.h"
#import <objc/runtime.h>
/**
 *  本类中做了EaseMob初始化和推送等操作
 */

//两次提示的默认间隔
static const CGFloat kDefaultPlaySoundInterval = 3.0;
static NSString *kMessageType = @"MessageType";
static NSString *kConversationChatter = @"ConversationChatter";
static void *LastPlaySoundDateKey = &LastPlaySoundDateKey;
@implementation AppDelegate (EaseMob)

- (void)easemobApplication:(UIApplication *)application
didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{

    objc_setAssociatedObject([UIApplication sharedApplication], LastPlaySoundDateKey,[NSDate date],OBJC_ASSOCIATION_COPY_NONATOMIC);
    
    [APService setBadge:0];
    if (launchOptions) {
        NSDictionary*userInfo = [launchOptions objectForKey:@"UIApplicationLaunchOptionsRemoteNotificationKey"];
        if(userInfo)
        {
            [self didReceiveRemoteNotification:userInfo];
        }
    }
    
    NSString *plistPath = [[NSBundle mainBundle] pathForResource:@"EaseSDK_Params" ofType:@"plist"];
    NSDictionary *data = [[NSDictionary alloc] initWithContentsOfFile:plistPath];
    data=[data objectForKey:@"params"];
    
//#warning 初始化环信SDK，详细内容在AppDelegate+EaseMob.m 文件中
//#warning SDK注册 APNS文件的名字, 需要与后台上传证书时的名字一一对应
    NSString *apnsCertName = nil;
#if DEBUG
    apnsCertName = [data objectForKey:@"CERTIFICATE_DEBUG_KEY"];
#else
    apnsCertName = [data objectForKey:@"CERTIFICATE_RELEASE_KEY"];
#endif

    NSString*appkey=[data objectForKey:@"APP_KEY"];
    [[EaseSDKHelper shareHelper] easemobApplication:application
                    didFinishLaunchingWithOptions:launchOptions
                                           appkey:appkey
                                     apnsCertName:apnsCertName
                                      otherConfig:@{kSDKConfigEnableConsoleLogger:[NSNumber numberWithBool:YES]}];
    
    [self registerEaseMobNotification];
    
    [[UINavigationBar appearance] setTitleTextAttributes:@{NSFontAttributeName :[UIFont systemFontOfSize:17],
                                                           NSForegroundColorAttributeName: [Utils colorWithHexString:@"#252729"]}];
    
    if( ([[[UIDevice currentDevice] systemVersion] doubleValue]>=7.0)) {
        [[UINavigationBar appearance] setTranslucent:NO];
    }
}

#pragma mark - App Delegate
// 将得到的deviceToken传给SDK
- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
    [[EaseMob sharedInstance] application:application didRegisterForRemoteNotificationsWithDeviceToken:deviceToken];
}

// 注册deviceToken失败，此处失败，与环信SDK无关，一般是您的环境配置或者证书配置有误
- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error
{
    [[EaseMob sharedInstance] application:application didFailToRegisterForRemoteNotificationsWithError:error];
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"apns.failToRegisterApns", Fail to register apns)
                                                    message:error.description
                                                   delegate:nil
                                          cancelButtonTitle:NSLocalizedString(@"ok", @"OK")
                                          otherButtonTitles:nil];
    [alert show];
}

#pragma mark - IChatManagerDelegate

- (void)didLoginFromOtherDevice
{
    NSDictionary *dict=@{@"messageType":@(7)};
    [[NSNotificationCenter defaultCenter] postNotificationName:sendMsgToWebView object:dict];
}

#pragma mark - EMChatManagerGroupDelegate

// 离开群组回调
- (void)group:(EMGroup *)group didLeave:(EMGroupLeaveReason)reason error:(EMError *)error
{
    if(reason==eGroupLeaveReason_UserLeave)
    {
       return;
    }
    NSInteger msg_type=reason+3;
    NSDictionary *msg_data=@{@"chat_id":group.groupId};
    NSDictionary *dict=@{@"messageType":@(msg_type),@"messageData":msg_data};
    [[NSNotificationCenter defaultCenter] postNotificationName:sendMsgToWebView object:dict];
    
    /*
    NSString *tmpStr = group.groupSubject;
    NSString *str;
    if (!tmpStr || tmpStr.length == 0) {
        NSArray *groupArray = [[EaseMob sharedInstance].chatManager groupList];
        for (EMGroup *obj in groupArray) {
            if ([obj.groupId isEqualToString:group.groupId]) {
                tmpStr = obj.groupSubject;
                break;
            }
        }
    }
    
    if (reason == eGroupLeaveReason_BeRemoved) {
        str = [NSString stringWithFormat:NSLocalizedString(@"group.beKicked", @"you have been kicked out from the group of \'%@\'"), tmpStr];
    }
    if (str.length > 0) {
        TTAlertNoTitle(str);
    }
    */
}

//// 申请加入群组被拒绝回调
//- (void)didReceiveRejectApplyToJoinGroupFrom:(NSString *)fromId
//                                   groupname:(NSString *)groupname
//                                      reason:(NSString *)reason
//                                       error:(EMError *)error{
//    if (!reason || reason.length == 0) {
//        reason = [NSString stringWithFormat:NSLocalizedString(@"group.beRefusedToJoin", @"be refused to join the group\'%@\'"), groupname];
//    }
//    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"prompt", @"Prompt") message:reason delegate:nil cancelButtonTitle:NSLocalizedString(@"ok", @"OK") otherButtonTitles:nil, nil];
//    [alertView show];
//}


// 已经同意并且加入群组后的回调
- (void)didAcceptInvitationFromGroup:(EMGroup *)group
                               error:(EMError *)error
{
    NSDictionary *msg_data=@{@"chat_id":group.groupId};
    NSDictionary *dict=@{@"messageType":@(3),@"messageData":msg_data};
    [[NSNotificationCenter defaultCenter] postNotificationName:sendMsgToWebView object:dict];
    /*
    if(error){
        return;
    }
    
    NSString *groupTag = group.groupSubject;
    if ([groupTag length] == 0) {
        groupTag = group.groupId;
    }
    
    NSString *message = [NSString stringWithFormat:NSLocalizedString(@"group.agreedAndJoined", @"agreed and joined the group of \'%@\'"), groupTag];
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"prompt", @"Prompt") message:message delegate:nil cancelButtonTitle:NSLocalizedString(@"ok", @"OK") otherButtonTitles:nil, nil];
    [alertView show];
    */
}

#pragma mark - EMChatManagerUtilDelegate

-(void)didReceiveMessage:(EMMessage *)message
{
    EMConversation *conversation=[[EaseMob sharedInstance].chatManager conversationForChatter:message.from conversationType:(EMConversationType)message.messageType];
    NSNumber *unreadMessagesCount=[NSNumber numberWithUnsignedInteger:conversation.unreadMessagesCount];
    NSDictionary *dict=@{@"chat_id":message.from,@"title":[EasemobPlugin getMessageTitle:message],@"timestamp":[NSNumber numberWithLongLong:message.timestamp],@"unread_count":unreadMessagesCount};
    [[NSNotificationCenter defaultCenter] postNotificationName:networkDidReceiveMessageFromIM
                                                        object:dict];
#if !TARGET_IPHONE_SIMULATOR
        UIApplicationState state = [[UIApplication sharedApplication] applicationState];
        switch (state) {
            case UIApplicationStateBackground:
                [self showNotificationWithMessage:message];
                break;
            default:
                break;
        }
#endif

}


- (void)showNotificationWithMessage:(EMMessage *)message
{
    //发送本地推送
    UILocalNotification *notification = [[UILocalNotification alloc] init];
    notification.fireDate = [NSDate date]; //触发通知的时间
    
    id<IEMMessageBody> messageBody = [message.messageBodies firstObject];
    NSString *messageStr = nil;
    switch (messageBody.messageBodyType) {
            case eMessageBodyType_Text:
            {
                messageStr = ((EMTextMessageBody *)messageBody).text;
            }
                break;
            case eMessageBodyType_Image:
            {
                messageStr = NSLocalizedString(@"message.image", @"Image");
            }
                break;
            case eMessageBodyType_Location:
            {
                messageStr = NSLocalizedString(@"message.location", @"Location");
            }
                break;
            case eMessageBodyType_Voice:
            {
                messageStr = NSLocalizedString(@"message.voice", @"Voice");
            }
                break;
            case eMessageBodyType_Video:{
                messageStr = NSLocalizedString(@"message.video", @"Video");
            }
                break;
            default:
                break;
        }
        
        NSString *title=@"您有一条私信消息";
//        NSString *title = [[UserProfileManager sharedInstance] getNickNameWithUsername:message.from];
        if (message.messageType == eMessageTypeGroupChat)
        {
            NSArray *groupArray = [[EaseMob sharedInstance].chatManager groupList];
            for (EMGroup *group in groupArray) {
                if ([group.groupId isEqualToString:message.conversationChatter]) {
                    title = [NSString stringWithFormat:@"%@", group.groupSubject];
                    break;
                }
            }
            
        }
        else if (message.messageType == eMessageTypeChatRoom)
        {
            NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
            NSString *key = [NSString stringWithFormat:@"OnceJoinedChatrooms_%@", [[[EaseMob sharedInstance].chatManager loginInfo] objectForKey:@"username" ]];
            NSMutableDictionary *chatrooms = [NSMutableDictionary dictionaryWithDictionary:[ud objectForKey:key]];
            NSString *chatroomName = [chatrooms objectForKey:message.conversationChatter];
            if (chatroomName)
            {
                title = [NSString stringWithFormat:@"来自聊天室<%@>",chatroomName];
            }
        }
        
        notification.alertBody = [NSString stringWithFormat:@"%@:%@", title, messageStr];

   
    
//#warning 去掉注释会显示[本地]开头, 方便在开发中区分是否为本地推送
    //notification.alertBody = [[NSString alloc] initWithFormat:@"[本地]%@", notification.alertBody];
    
    notification.alertAction = NSLocalizedString(@"open", @"Open");
    notification.timeZone = [NSTimeZone defaultTimeZone];
    
    NSDate* lastPlaySoundDate =objc_getAssociatedObject([UIApplication sharedApplication],LastPlaySoundDateKey);
    NSTimeInterval timeInterval = [[NSDate date] timeIntervalSinceDate:lastPlaySoundDate];
    if (timeInterval < kDefaultPlaySoundInterval) {
            NSLog(@"skip ringing & vibration %@, %@", [NSDate date],lastPlaySoundDate);
        } else {
            notification.soundName = UILocalNotificationDefaultSoundName;
            lastPlaySoundDate = [NSDate date];
            objc_setAssociatedObject([UIApplication sharedApplication], LastPlaySoundDateKey,lastPlaySoundDate,OBJC_ASSOCIATION_COPY_NONATOMIC);
    }
    
   
    
    notification.userInfo = @{kMessageType:[NSNumber numberWithInt:message.messageType],kConversationChatter:message.conversationChatter};

    //发送通知
    [[UIApplication sharedApplication] scheduleLocalNotification:notification];
    //    UIApplication *application = [UIApplication sharedApplication];
    //    application.applicationIconBadgeNumber += 1;
}



//// 网络状态变化回调
//- (void)didConnectionStateChanged:(EMConnectionState)connectionState
//{
////    _connectionState = connectionState;
////    [self.mainController networkChanged:connectionState];
//}

#pragma mark - EMPushManagerDelegateDevice

// 绑定deviceToken回调
- (void)didBindDeviceWithError:(EMError *)error
{
    if (error) {
        //        TTAlertNoTitle(NSLocalizedString(@"apns.failToBindDeviceToken", @"Fail to bind device token"));
    }
}

// 打印收到的apns信息
-(void)didReceiveRemoteNotification:(NSDictionary *)userInfo
{
//    NSError *parseError = nil;
//    NSData  *jsonData = [NSJSONSerialization dataWithJSONObject:userInfo
//                                                        options:NSJSONWritingPrettyPrinted error:&parseError];
//    NSString *str =  [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
//    
//    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"apns.content", @"Apns content")
//                                                    message:str
//                                                   delegate:nil
//                                          cancelButtonTitle:NSLocalizedString(@"ok", @"OK")
//                                          otherButtonTitles:nil];
//    [alert show];
    
}

#pragma mark - registerEaseMobNotification
- (void)registerEaseMobNotification{
    [self unRegisterEaseMobNotification];
    // 将self 添加到SDK回调中，以便本类可以收到SDK回调
    [[EaseMob sharedInstance].chatManager addDelegate:self delegateQueue:nil];
}

- (void)unRegisterEaseMobNotification{
    [[EaseMob sharedInstance].chatManager removeDelegate:self];
}

//统计未读消息数
-(void)setupUnreadMessageCount
{
    id<IChatManager> chatManager=[[EaseMob sharedInstance] chatManager];
    if([chatManager isLoggedIn])
    {
     NSInteger unreadCount=[chatManager loadTotalUnreadMessagesCountFromDatabase];
     [APService setBadge:0];
     UIApplication *application = [UIApplication sharedApplication];
     [application setApplicationIconBadgeNumber:unreadCount];
    }
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    //[[UIApplication sharedApplication] setApplicationIconBadgeNumber:0];
    [self setupUnreadMessageCount];
}

@end
