//
//  EasemobPlugin.m
//  泛艺术
//
//  Created by zsly on 16/2/22.
//
//

#import "EasemobPlugin.h"
#import "EaseMob.h"
#import "APService.h"
#import "TTGlobalUICommon.h"
@implementation EasemobPlugin
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

             NSString *JsonString=[self JsonString:@{@"key":[NSNumber numberWithInteger:0]}];
            
             dispatch_async(dispatch_get_main_queue(), ^{
                 [self.commandDelegate evalJs:[NSString stringWithFormat:@"cordova.fireDocumentEvent('Easemob.receiveEasemobMessage',%@)",JsonString]];
             });
         }
         else
         {
             NSString *JsonString=[self JsonString:@{@"key":[NSNumber numberWithInteger:1]}];
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
