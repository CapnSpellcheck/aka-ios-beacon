//
//  AppDelegate.m
//  AKABeaconDemo
//
//  Created by Michael Utech on 23.09.15.
//  Copyright © 2015 AKA Sarl. All rights reserved.
//

@import AKABeacon;

#import "AppDelegate.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
#if 0
    AKA_LOG_LEVEL_DEF = DDLogLevelAll;
    [DDLog addLogger:[DDTTYLogger sharedInstance] withLevel:DDLogLevelWarning]; // TTY = Xcode console
    [DDLog addLogger:[DDASLLogger sharedInstance] withLevel:DDLogLevelWarning]; // ASL = Apple System Logs
    [DDLog setLevel:DDLogLevelAll forClass:[AKATVMultiplexedDataSource class]];
#endif

    // Override point for customization after application launch.
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
}

- (void)applicationWillTerminate:(UIApplication *)application
{
}

@end
