//
//  EasemobPlugin.h
//  泛艺术
//
//  Created by zsly on 16/2/22.
//
//

#import <Cordova/CDV.h>
@interface EasemobPlugin : CDVPlugin

/*环信异步登陆*/
-(void)login:(CDVInvokedUrlCommand*)command;

/*环信异步登出*/
-(void)logOut:(CDVInvokedUrlCommand*)command;
@end
