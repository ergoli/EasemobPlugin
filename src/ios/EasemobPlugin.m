//
//  EasemobPlugin.m
//  泛艺术
//
//  Created by zsly on 16/2/22.
//
//

#import "EasemobPlugin.h"
#import "EaseMob.h"
#import "EaseConversationModel.h"
#import "EaseConvertToCommonEmoticonsHelper.h"
#import "EaseEmotionManager.h"
#import "APService.h"
#import "TTGlobalUICommon.h"
@implementation EasemobPlugin

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
                    NSString*title=[self getMessageTitle:lastMessage];
                    NSNumber *timestamp=[NSNumber numberWithLongLong:lastMessage.timestamp];
                    [rs_array addObject:@{@"chat_id":chatter,@"title":title,@"timestamp":timestamp}];
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

-(NSString*)getMessageTitle:(EMMessage *)message
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
    [[EaseMob sharedInstance].chatManager asyncLoginWithUsername:username
                                                        password:password
                                                      completion:
     ^(NSDictionary *loginInfo, EMError *error) {
         
         if (loginInfo && !error) {
             //设置是否自动登录
             [[EaseMob sharedInstance].chatManager setIsAutoLoginEnabled:NO];
             
             // 旧数据转换 (如果您的sdk是由2.1.2版本升级过来的，需要家这句话)
             [[EaseMob sharedInstance].chatManager importDataToNewDatabase];
             //获取数据库中数据
             [[EaseMob sharedInstance].chatManager loadDataFromDatabase];
             
             //获取群组列表
             [[EaseMob sharedInstance].chatManager asyncFetchMyGroupsList];

             NSString *JsonString=[self JsonString:@{@"messageType":[NSNumber numberWithInteger:0]}];
            
             dispatch_async(dispatch_get_main_queue(), ^{
                 [self.commandDelegate evalJs:[NSString stringWithFormat:@"cordova.fireDocumentEvent('Easemob.receiveEasemobMessage',%@)",JsonString]];
             });
         }
         else
         {
             NSInteger rs=1;
             if(error.errorCode==EMErrorServerTooManyOperations)
             {
                 rs=0;
             }
             NSString *JsonString=[self JsonString:@{@"messageType":[NSNumber numberWithInteger:rs]}];
             dispatch_async(dispatch_get_main_queue(), ^{
                 [self.commandDelegate evalJs:[NSString stringWithFormat:@"cordova.fireDocumentEvent('Easemob.receiveEasemobMessage',%@)",JsonString]];
             });
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
     } onQueue:nil];
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
}


-(NSString*)JsonString:(id)obj
{
    NSError  *error;
    NSData   *jsonData   = [NSJSONSerialization dataWithJSONObject:obj options:0 error:&error];
    NSString *jsonString = [[NSString alloc]initWithData:jsonData encoding:NSUTF8StringEncoding];
    return jsonString;
}




@end
