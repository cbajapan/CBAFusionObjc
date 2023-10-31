//#if NSFoundationVersionNumber > 12
#import <UIKit/UIKit.h>
#import "LoginViewController.h"
#import "UCClientTabbedViewController.h"
#import <UserNotifications/UserNotifications.h>
#import "AuthenticationService.h"
#import "NetworkMonitor.h"


API_AVAILABLE(ios(13))
@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property BOOL userWantsToBeLoggedIn;

@property (readonly) AuthenticationService *authenticationService;
@property (readonly) NetworkMonitor *networkMonitor;
@property (strong) LoginViewController *loginViewController;
@property (strong) UCClientTabbedViewController *tabbedViewController;

@property (strong, nonatomic) UIWindow *window;

@end
//#else
//#import <UIKit/UIKit.h>
//@interface AppDelegate : UIResponder <UIApplicationDelegate>
//
//
//@property (strong, nonatomic) UIWindow *window;
//@end
//#endif
