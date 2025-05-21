//#if NSFoundationVersionNumber > 12
#import "AppDelegate.h"
#import "ConnectivityManager.h"
#import "AppSettings.h"
#import <UserNotifications/UserNotifications.h>

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
    _networkMonitor = [[NetworkMonitor new] init];
    _authenticationService = [[AuthenticationService new] init];

    
    UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
    [center requestAuthorizationWithOptions:(UNAuthorizationOptionBadge | UNAuthorizationOptionSound | UNAuthorizationOptionAlert)
                          completionHandler:^(BOOL granted, NSError * _Nullable error) {
                              if (!error) {
                                  NSLog(@"request authorization succeeded!");
                              }
                          }];
    [AppSettings registerDefaults];
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
	UIApplication *app = [UIApplication sharedApplication];
	__block UIBackgroundTaskIdentifier bgTask = [app beginBackgroundTaskWithExpirationHandler:^{
		[app endBackgroundTask: bgTask];
	}];

	[NSTimer timerWithTimeInterval:[app backgroundTimeRemaining]-5 target:self selector:@selector(endBgTask:) userInfo:[NSNumber numberWithUnsignedInt:     (uint)bgTask] repeats:NO];
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)endBgTask:(NSTimer *)timer
{
    UIBackgroundTaskIdentifier identfier = (UIBackgroundTaskIdentifier)timer.userInfo;
	[[UIApplication sharedApplication] endBackgroundTask:identfier];
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    [_networkMonitor stopNetworkMonitoring];
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}
@end


 
