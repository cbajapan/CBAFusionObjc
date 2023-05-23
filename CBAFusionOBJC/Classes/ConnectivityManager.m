//#import "ConnectivityManager.h"
//#import "ClientHTTPSConnectionHandler.h"
//#import "ImSampleAppDelegate.h"
//#import "UCClientTabbedViewController.h"
//
//@interface ConnectivityManager()
//{
//	ACBUC *_uc;
//    UIView *hider;
//	NSString *server;
//	NSString *configuration;
//    int automaticLoginReattempts;
//    NSTimeInterval lastReconnectionAttempt;
//}
//
//@property (retain) ReachabilityManager *reachabilityManager;
//
//@end
//
//@implementation ConnectivityManager
//
//- (void)loginWithHider:(BOOL)hiderOn
//{
//    if (hiderOn)
//    {
//        [self hider:YES];
//    }
//	NSString *username = [[NSUserDefaults standardUserDefaults] objectForKey:@"username"];
//	NSString *password = [[NSUserDefaults standardUserDefaults] objectForKey:@"password"];
//	server             = [[NSUserDefaults standardUserDefaults] objectForKey:@"server"];
//    NSNumber *port     = [[NSUserDefaults standardUserDefaults] objectForKey:@"port"];
//    
//    if (port == nil)
//    {
//        port = @8080;
//    }
//
//    NSNumber *secureNumber = [[NSUserDefaults standardUserDefaults] objectForKey:@"secureSwitch"];
//    BOOL secure = [secureNumber boolValue];
//    
//    NSString *scheme = secure ? @"https" : @"http";
//    
//    NSString *URL    = [NSString stringWithFormat:@"%@://%@:%@/csdk-sample/SDK/login", scheme, server, port];
//    
//    NSNumber *acceptCertificateNumber = [[NSUserDefaults standardUserDefaults] objectForKey:@"acceptUntrustedCertificates"];
//    BOOL acceptUntrustedCertificates = [acceptCertificateNumber boolValue];
//                                         
//	NSArray *objects = [NSArray arrayWithObjects:username, password, nil];
//    NSArray *keys    = [NSArray arrayWithObjects:@"username", @"password", nil];
//    NSData *payload  = [NSJSONSerialization dataWithJSONObject:[NSDictionary dictionaryWithObjects:objects forKeys:keys] options:0 error:nil];
//	NSMutableDictionary *headers = [NSMutableDictionary dictionaryWithObject:@"application/json" forKey:@"Content-Type"];
//	
//    automaticLoginReattempts++;
//
//	ClientHTTPSConnectionHandler *handler = [[ClientHTTPSConnectionHandler alloc] initWithUrlString:URL acceptUntrustedCertificates:acceptUntrustedCertificates method:@"POST" andHeaders:headers andPayload:payload andNotify:self];
//#pragma unused(handler)
//}
//
//- (void) logout
//{
//    NSLog(@"Starting logout - Server %@ Configuration %@", server, configuration);
//    NSNumber *port = [[NSUserDefaults standardUserDefaults] objectForKey:@"port"];
//    if (port == nil)
//    {
//        port = @8080;
//    }
//    
//    BOOL secure = [[[NSUserDefaults standardUserDefaults] objectForKey:@"secureSwitch"] boolValue];
//    NSString *scheme = secure ? @"https" : @"http";
//
//    NSString *URL = [NSString stringWithFormat:@"%@://%@:%@/csdk-sample/SDK/login/id/%@", scheme, server, port, configuration];
//    BOOL acceptUntrustedCertificates = [[[NSUserDefaults standardUserDefaults] objectForKey:@"acceptUntrustedCertificates"] boolValue];
//
//	ClientHTTPSConnectionHandler *handler = [[ClientHTTPSConnectionHandler alloc] initWithUrlString:URL acceptUntrustedCertificates:acceptUntrustedCertificates
//method:@"DELETE" andHeaders:nil andPayload:nil andNotify:self];
//#pragma unused(handler)
//}
//
//-(void)errorHappened:(NSError *)error
//{
//    dispatch_async(dispatch_get_main_queue(), ^{
//        [self hider:NO];
//        
//        
//        UIAlertController * alert = [UIAlertController alertControllerWithTitle:@"CONNECTION ERROR" message:error.localizedDescription preferredStyle:UIAlertControllerStyleAlert];
//        
//        
//             UIAlertAction * actionOK = [UIAlertAction actionWithTitle:@"Button Title" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
//                                //Here Add Your Action
//                            }];
//             UIAlertAction * actionCANCEL = [UIAlertAction actionWithTitle:@"Second Button Title" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
//                                //Add Another Action
//                            }];
//
//
//                       [alert addAction:actionOK];
//                     [alert addAction:actionCANCEL];
//
////           [self presentViewController:alert animated:YES completion:nil];
//        
//        
////        [[[UIAlertView alloc] initWithTitle:@"CONNECTION ERROR" message:error.localizedDescription
////                                   delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
//    });
//}
//
//-(void)dataLoaded:(NSData *)nsData
//{
//    // nsData will be empty on logout.
//    if (nsData.length > 0)
//    {
//        NSError *error = nil;
//        NSDictionary *response = [NSJSONSerialization JSONObjectWithData:nsData options:0 error:&error];
//
//        if (error != nil)
//        {
//            NSLog(@"Error decoding JSON response from REST login API: %@", [error localizedDescription]);
//            NSLog(@"JSON response: %@", nsData);
//            NSString *dataStr = [[NSString alloc] initWithData:nsData encoding:NSASCIIStringEncoding];
//            NSLog(@"JSON Decoded: %@", dataStr);
//            // TODO display error
//            dispatch_async(dispatch_get_main_queue(), ^{
//                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Login/Logout failed!" message:[NSString stringWithFormat:@"Failed to log in/out. %@", [error localizedDescription]] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
//                [alert show];
//                
//                [self hider:NO];
//            });
//        }
//        else
//        {
//            configuration = [response objectForKey:@"sessionid"];
//            NSLog(@"Got session : %@", configuration);
//            
//            // The following line of code creates a UC object using the configuration retrieved from the gateway
//            _uc = [ACBUC ucWithConfiguration:configuration delegate:self];
//           
//            
//            // The following code can be used instead if STUN is required
//        
//            // NSArray* stunServers = [NSArray arrayWithObject:@"stun:stun.l.google.com:19302"];
//            // _uc = [ACBUC ucWithConfiguration:configuration stunServers:stunServers delegate:self];
//        
//            [self registerForReachabilityCallback];
//        
//        
//            BOOL acceptUntrustedCertificates = [[[NSUserDefaults standardUserDefaults] objectForKey:@"acceptUntrustedCertificates"] boolValue];
//            [_uc acceptAnyCertificate:acceptUntrustedCertificates];
//        
//            NSNumber *useCookiesNumber = [[NSUserDefaults standardUserDefaults] objectForKey:@"useCookies"];
//            _uc.useCookies = [useCookiesNumber boolValue];
//        
//            [_uc startSession];
//        }
//    }
//}
//
//- (void)hider:(BOOL)on
//{
//	if (on)
//	{
//		UIApplication *app = [UIApplication sharedApplication];
//		UIWindow *window = [app.windows objectAtIndex:0];
//		hider = [[UIView alloc] initWithFrame:window.frame];
//		hider.alpha = 0.3f;
//		hider.backgroundColor = [UIColor blackColor];
//		UIView *view = [window.subviews objectAtIndex:0];
//		[view insertSubview:hider atIndex:view.subviews.count];
//	}
//	else
//	{
//        dispatch_async(dispatch_get_main_queue(), ^{
//            [self->hider removeFromSuperview];
//            self->hider = Nil;
//        });
//	}
//}
//
///**
// * A notification to indicate that the session has been initialised successfully.
// */
//- (void) ucDidStartSession:(ACBUC *)uc
//{
//    dispatch_async(dispatch_get_main_queue(), ^{
//        [self hider:NO];
//        ImSampleAppDelegate *appDelegate = (ImSampleAppDelegate *)[UIApplication sharedApplication].delegate;
//        UITabBarItem *accountTab = appDelegate.tabbedViewController.tabBar.items.lastObject;
//        accountTab.badgeValue = nil;
//        
//        self->automaticLoginReattempts = 0;
//    LoginViewController *loginViewController = appDelegate.loginViewController;
//        loginViewController.uc = self->_uc;
//        loginViewController.configuration = self->configuration;
//    // TODO - not to perform the segue if the user logged out manually, or in other words perform it only after a non-repeated login from the Login view controller. This is not causing a problem, anyway, as the segue doesn't seem to operate if the login form is not on top.
//        [loginViewController performSegueWithIdentifier:@"loginSegue" sender:self];
//    });
//}
//
///**
// * A notification to indicate that initialisation of the session failed.
// */
//- (void) ucDidFailToStartSession:(ACBUC *)uc
//{
//    dispatch_async(dispatch_get_main_queue(), ^{
//        [[[UIAlertView alloc] initWithTitle:@"Registration error" message:@"Registration failed" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
//        [self hider:NO];
//    });
//}
//
///**
// * A notification to indicate that the session has been invalidated due to a network drop.
// *
// * @param uc
// *            The UC.
// */
//- (void) ucDidLoseConnection:(ACBUC *)uc
//{
//    [self logout];
//	// TODO On loss of connection we currently choose to log in again. This should be done automatically.
//
//    
//    ImSampleAppDelegate *appDelegate = (ImSampleAppDelegate *)[[UIApplication sharedApplication] delegate];
//    
//    if (!appDelegate.userWantsToBeLoggedIn)
//    {
//        return;
//    }
//
//    UITabBarItem *accountTab = appDelegate.tabbedViewController.tabBar.items.lastObject;
//    if ((automaticLoginReattempts >= 2) ||
//        (lastReconnectionAttempt >= [NSDate timeIntervalSinceReferenceDate] - 30))
//    {
//        accountTab.badgeValue = @"Logged Out";
//    }
//    else
//    {
//        accountTab.badgeValue = @"...logging in...";
//        lastReconnectionAttempt = [NSDate timeIntervalSinceReferenceDate];
//        [self loginWithHider:NO];
//    }
//}
//
//- (void) ucDidReceiveSystemFailure:(ACBUC *)uc
//{
//    dispatch_async(dispatch_get_main_queue(), ^{
//        [[[UIAlertView alloc] initWithTitle:@"ERROR" message:@"System failure. Please log in again." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
//        [self logout];
//    });
//}
//
//#pragma mark - Reachability
//- (void)registerForReachabilityCallback
//{
//	// Do any additional setup after loading the view.
//    self.reachabilityManager = [[ReachabilityManager alloc] init];
//    [self.reachabilityManager addListener:self];
//    [self.reachabilityManager registerForReachabilityTo:server];
//}
//
//- (void)unregisterForReachabilityCallback
//{
//    // remove the reachability callback listener
//    if (self.reachabilityManager != nil)
//    {
//        [self.reachabilityManager removeListener:self];
//    }
//}
//
//#pragma mark -
//#pragma mark ReachabilityManagerListener
//- (void) reachabilityDetermined:(BOOL)reachability
//{
//	NSLog(@"Network reachability changed to:%@ - here the application has the chance to inform the user that connectivitiy is lost", reachability ? @"YES" : @"NO");
//	[_uc setNetworkReachable:reachability];
//}
//
//@end
