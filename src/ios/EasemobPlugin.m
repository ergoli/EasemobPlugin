//
//  EasemobPlugin.m
//  泛艺术
//
//  Created by zsly on 16/2/22.
//
//

#import "EasemobPlugin.h"
#import "EaseMessageViewController.h"
#import "EaseConversationModel.h"
#import "EaseConvertToCommonEmoticonsHelper.h"
#import "EaseEmotionManager.h"
#import "APService.h"
#import "AppDelegate.h"
#import "AppDelegate+EaseMob.h"
#import "TTGlobalUICommon.h"
#import "ChatViewController.h"
#import <objc/runtime.h>

@implementation EasemobPlugin

- (CDVPlugin*)initWithWebView:(UIWebView*)theWebView{
    if (self=[super initWithWebView:theWebView]) {
        
        NSNotificationCenter *defaultCenter_0 = [NSNotificationCenter defaultCenter];
        [defaultCenter_0 addObserver:self
                          selector:@selector(networkDidReceiveMessageFromIM:)
                              name:networkDidReceiveMessageFromIM
                            object:nil];
        
        NSNotificationCenter *defaultCenter_1 = [NSNotificationCenter defaultCenter];
        [defaultCenter_1 addObserver:self
                          selector:@selector(sendMsgToWebView:)
                              name:sendMsgToWebView
                            object:nil];
    }
    return self;
}

-(void)chat:(CDVInvokedUrlCommand*)command
{
   //[self CreateChatVC:@"" conversationType:eConversationTypeChat];
}

-(void)chatRoom:(CDVInvokedUrlCommand*)command
{
    NSString *group_ID=command.arguments[0];
    NSDictionary *userInfo=command.arguments[1];
    NSString *groupName=command.arguments[2];
    [self CreateChatVC:group_ID conversationType:eConversationTypeGroupChat userInfo:userInfo title:groupName];
}

-(void)CreateChatVC:(NSString *)conversationChatter conversationType:(EMConversationType)conversationType userInfo:(NSDictionary*)userInfo title:(NSString*)title
{
    AppDelegate *app_delegate=(AppDelegate*)[UIApplication sharedApplication].delegate;
    app_delegate.accessibilityValue=conversationChatter;
    
    
    ChatViewController *chat=[[ChatViewController alloc] initWithConversationChatter:conversationChatter conversationType:eConversationTypeGroupChat];
    chat.nav_title=title;
    chat.userInfo=userInfo;

    UINavigationController *nav=[[UINavigationController alloc] initWithRootViewController:chat];
   
    [app_delegate.viewController presentViewController:nav animated:YES completion:nil];
}

/*应用内接收环信消息*/
-(void)sendMsgToWebView:(id)notification
{
    NSDictionary *dict = [notification object];
    NSString *JsonString=[self JsonString:dict];
    [self sendMsg:JsonString];
}

/*应用内接收环信消息*/
-(void)networkDidReceiveMessageFromIM:(id)notification
{
    NSDictionary *dict = [notification object];
    NSString *JsonString=[self JsonString:@{@"messageType":@(received_msg),@"messageData":dict}];
    [self sendMsg:JsonString];
}

-(void)sendMsg:(NSString*)JsonString
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.commandDelegate evalJs:[NSString stringWithFormat:@"cordova.fireDocumentEvent('Easemob.receiveEasemobMessage',%@)",JsonString]];
    });
}

/*根据数组id获取环信会话信息*/
-(void)getLatestMessage:(CDVInvokedUrlCommand*)command
{
    NSArray *array_ID=command.arguments[0];
    NSMutableArray *rs_array=[NSMutableArray arrayWithCapacity:array_ID.count];
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        NSArray *conversations = [[EaseMob sharedInstance].chatManager conversations];
        for (NSString* chatter in array_ID) {
            for (EMConversation *obj in conversations) {
                if([chatter isEqualToString:obj.chatter])
                {
                    EMMessage *lastMessage = [obj latestMessage];
                    NSString*title=[EasemobPlugin getMessageTitle:lastMessage];
                    NSNumber *timestamp=[NSNumber numberWithLongLong:lastMessage.timestamp];
                    NSNumber *unreadMessagesCount=[NSNumber numberWithUnsignedInteger:obj.unreadMessagesCount];
                    [rs_array addObject:@{@"chat_id":chatter,@"title":title,@"timestamp":timestamp,@"unread_count":unreadMessagesCount}];
                    break;
                }
            }
        }
        NSArray* sorted = [rs_array sortedArrayUsingComparator:
                           ^(NSDictionary *obj1, NSDictionary* obj2){
                               NSNumber *timestamp1 = [obj1 objectForKey:@"timestamp"];
                               NSNumber *timestamp2 = [obj2 objectForKey:@"timestamp"];
                               if(timestamp1.longLongValue > timestamp2.longLongValue) {
                                   return(NSComparisonResult)NSOrderedAscending;
                               }else {
                                   return(NSComparisonResult)NSOrderedDescending;
                               }
        }];
        
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArray:sorted];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
        });
        
    });

}

+(NSString*)getMessageTitle:(EMMessage *)message
{
    NSString *messageTitle=nil;
    id<IEMMessageBody> messageBody =message.messageBodies.lastObject;
    switch (messageBody.messageBodyType) {
        case eMessageBodyType_Image:{
            messageTitle = NSLocalizedString(@"message.image1", @"[image]");
        } break;
        case eMessageBodyType_Text:{
            // 表情映射。
            NSString *didReceiveText = [EaseConvertToCommonEmoticonsHelper
                                        convertToSystemEmoticons:((EMTextMessageBody *)messageBody).text];
            messageTitle = didReceiveText;
            if ([message.ext objectForKey:MESSAGE_ATTR_IS_BIG_EXPRESSION]) {
                messageTitle = @"[动画表情]";
            }
        } break;
        case eMessageBodyType_Voice:{
            messageTitle = NSLocalizedString(@"message.voice1", @"[voice]");
        } break;
        case eMessageBodyType_Location: {
            messageTitle = NSLocalizedString(@"message.location1", @"[location]");
        } break;
        case eMessageBodyType_Video: {
            messageTitle = NSLocalizedString(@"message.video1", @"[video]");
        } break;
        case eMessageBodyType_File: {
            messageTitle = NSLocalizedString(@"message.file1", @"[file]");
        } break;
        default: {
        } break;
    }
    return messageTitle;
}

-(void)login:(CDVInvokedUrlCommand*)command
{
    NSString *username=command.arguments[0];
    NSString *password=command.arguments[1];
   
    __block BOOL isRedirectChatList=NO;
    AppDelegate *app_delegate=(AppDelegate*)[UIApplication sharedApplication].delegate;
    if(app_delegate.accessibilityValue&&[app_delegate.accessibilityValue isEqualToString:@"2"])
    {
        isRedirectChatList=YES;
        app_delegate.accessibilityValue=nil;
    }
    [[EaseMob sharedInstance].chatManager asyncLoginWithUsername:username
                                                        password:password
                                                      completion:
     ^(NSDictionary *loginInfo, EMError *error) {
         
         NSString *JsonString=nil;
         if (loginInfo && !error) {
             //设置是否自动登录
             [[EaseMob sharedInstance].chatManager setIsAutoLoginEnabled:NO];
             
             //旧数据转换 (如果您的sdk是由2.1.2版本升级过来的，需要家这句话)
             [[EaseMob sharedInstance].chatManager importDataToNewDatabase];
             //获取数据库中数据
             [[EaseMob sharedInstance].chatManager loadDataFromDatabase];
             
             //获取群组列表
             [[EaseMob sharedInstance].chatManager asyncFetchMyGroupsList];

             [self removeEmptyConversationsFromDB];
             
             NSInteger rs=[[EaseMob sharedInstance].chatManager loadTotalUnreadMessagesCountFromDatabase];
            
             JsonString=[self JsonString:@{@"messageType":@(login_successed),@"messageData":@{@"unread_count":@(rs),@"isRedirectChatList":@(isRedirectChatList)}}];
             
         }
         else
         {
             NSInteger rs=login_failed;
             if(error.errorCode==EMErrorServerTooManyOperations)
             {
                 rs=login_successed;
             }
             else
             {
                 isRedirectChatList=NO;
             }
             JsonString=[self JsonString:@{@"messageType":@(rs),@"messageData":@{@"isRedirectChatList":@(isRedirectChatList)}}];

             
             /*
             switch (error.errorCode)
             {
                 case EMErrorNotFound:
                     TTAlertNoTitle(error.description);
                     break;
                 case EMErrorNetworkNotConnected:
                     TTAlertNoTitle(NSLocalizedString(@"error.connectNetworkFail", @"No network connection!"));
                     break;
                 case EMErrorServerNotReachable:
                     TTAlertNoTitle(NSLocalizedString(@"error.connectServerFail", @"Connect to the server failed!"));
                     break;
                 case EMErrorServerAuthenticationFailure:
                     TTAlertNoTitle(error.description);
                     break;
                 case EMErrorServerTimeout:
                     TTAlertNoTitle(NSLocalizedString(@"error.connectServerTimeout", @"Connect to the server timed out!"));
                     break;
                 default:
                     TTAlertNoTitle(NSLocalizedString(@"login.fail", @"Login failure"));
                     break;
             }
             */
             
             
         }
         
         dispatch_async(dispatch_get_main_queue(), ^{
             
             [self.commandDelegate evalJs:[NSString stringWithFormat:@"cordova.fireDocumentEvent('Easemob.receiveEasemobMessage',%@)",JsonString]];
         });
         
     } onQueue:nil];
}

-(void)isLaunchWithJPush:(CDVInvokedUrlCommand*)command
{
    AppDelegate*app=(AppDelegate*)[UIApplication sharedApplication].delegate;
    NSString* value=app.accessibilityValue;
    BOOL isLaunchWithJPush=NO;
    if(value&&[value isEqualToString:@"1"])
    {
        isLaunchWithJPush=YES;
        app.accessibilityValue=nil;
    }
    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsBool:isLaunchWithJPush];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}


-(void)logOut:(CDVInvokedUrlCommand*)command
{
    //退出环信
    [[EaseMob sharedInstance].chatManager asyncLogoffWithUnbindDeviceToken:YES completion:^(NSDictionary *info, EMError *error) {
        if (!error && info) {
            //设置是否自动登录
            [[EaseMob sharedInstance].chatManager setIsAutoLoginEnabled:NO];
        }
    } onQueue:nil];
    
    [APService setAlias:@"000" callbackSelector:nil object:nil];
    [[UIApplication sharedApplication] unregisterForRemoteNotifications];
    [APService setBadge:0];
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:0];
}


-(NSString*)JsonString:(id)obj
{
    NSError  *error;
    NSData   *jsonData   = [NSJSONSerialization dataWithJSONObject:obj options:0 error:&error];
    NSString *jsonString = [[NSString alloc]initWithData:jsonData encoding:NSUTF8StringEncoding];
    return jsonString;
}

- (void)removeEmptyConversationsFromDB
{
    NSArray *conversations = [[EaseMob sharedInstance].chatManager conversations];
    NSMutableArray *needRemoveConversations;
    for (EMConversation *conversation in conversations) {
        if (!conversation.latestMessage || (conversation.conversationType == eConversationTypeChatRoom)) {
            if (!needRemoveConversations) {
                needRemoveConversations = [[NSMutableArray alloc] initWithCapacity:0];
            }
            
            [needRemoveConversations addObject:conversation.chatter];
        }
    }
    
    if (needRemoveConversations && needRemoveConversations.count > 0) {
        [[EaseMob sharedInstance].chatManager removeConversationsByChatters:needRemoveConversations
                                                             deleteMessages:YES                                                       append2Chat:NO];
    }
}



@end
