//
//  AuthenticationService.m
//  CBAFusionObjc
//
//  Created by Cole M on 11/28/22.
//  Copyright © 2022 AliceCallsBob. All rights reserved.
//
//#if NSFoundationVersionNumber > 12
//#import <Foundation/Foundation.h>
//#import "AuthenticationService.h"
//#import "AppDelegate.h"
//#import "UCClientTabbedViewController.h"
//#import <UserNotifications/UserNotifications.h>
//
//
//@import FCSDKiOS;
//
//API_AVAILABLE(ios(13))
//@interface AuthenticationService()
//{
//    ACBUC *_uc;
//    UIView *hider;
//    NSString *server;
//    NSString *configuration;
//    int automaticLoginReattempts;
//    NSTimeInterval lastReconnectionAttempt;
//}
//@end
//
//@implementation AuthenticationService
//
//- (void)createSession:(NSString *)sessionId status:(BOOL)networkStatus {
//
//    if (@available(iOS 13, *)) {
//        NSArray *strings = [[NSMutableArray alloc] init];
//        [ACBUC ucWithConfiguration:sessionId stunServers:strings delegate:self options: ACBUCOptions.noVoiceProcessing completionHandler:^(ACBUC * uc) {
//            [uc acceptAnyCertificate:true];
////        [ACBUC ucWithConfiguration:sessionId delegate:self completionHandler:^(ACBUC * uc) {
//            //We Need to temporarily set the delegate
//            [uc setNetworkReachable:networkStatus];
//            [uc.phone setDelegate:self];
////            BOOL acceptUntrustedCertificates = [[[NSUserDefaults standardUserDefaults] objectForKey:@"acceptUntrustedCertificates"] boolValue];
////            [uc acceptAnyCertificate:acceptUntrustedCertificates];
//            NSNumber *useCookiesNumber = [[NSUserDefaults standardUserDefaults] objectForKey:@"useCookies"];
//            uc.useCookies = [useCookiesNumber boolValue];
//
//            [uc startSessionWithTriggerReconnect:YES completionHandler:^{
//                self->_uc = uc;
//            }];
////            [uc startSession];
////
//        }];
//    } else {
//        // Fallback on earlier versions
//    }
//}
//
//- (void)hider:(BOOL)on
//{
//    if (on)
//    {
//        UIApplication *app = [UIApplication sharedApplication];
//        UIWindow *window = [app.windows objectAtIndex:0];
//        hider = [[UIView new] initWithFrame:window.frame];
//        hider.alpha = 0.3f;
//        hider.backgroundColor = [UIColor blackColor];
//        UIView *view = [window.subviews objectAtIndex:0];
//        [view insertSubview:hider atIndex:view.subviews.count];
//    }
//    else
//    {
//        dispatch_async(dispatch_get_main_queue(), ^{
//            [self->hider removeFromSuperview];
//            self->hider = Nil;
//        });
//    }
//}
//
//- (void)loginUser:(BOOL)networkStatus {
//    
//    if (networkStatus)
//    {
//        [self hider:YES];
//    }
//    NSString *username = [[NSUserDefaults standardUserDefaults] objectForKey:@"username"];
//    NSString *password = [[NSUserDefaults standardUserDefaults] objectForKey:@"password"];
//    server             = [[NSUserDefaults standardUserDefaults] objectForKey:@"server"];
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
//    NSString *string = [NSString stringWithFormat:@"%@://%@:%@/csdk-sample/SDK/login", scheme, server, port];
//    //    NSNumber *useCookies = [[NSUserDefaults standardUserDefaults] objectForKey:@"useCookies"];
//    
////        NSNumber *acceptCertificateNumber = [[NSUserDefaults standardUserDefaults] objectForKey:@"acceptUntrustedCertificates"];
////        BOOL acceptUntrustedCertificates = [acceptCertificateNumber boolValue];
//    
//    
//    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
////    NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration];
//    NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration delegate:self delegateQueue:nil];
//    
//    
//    NSURL *URL = [NSURL URLWithString:string];
//    
//    
//    NSMutableURLRequest *request = [[NSMutableURLRequest new] initWithURL:URL];
//    
//    NSArray* allCookies = [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookies];
//    for (NSHTTPCookie* cookie in allCookies)
//    {
//        [[NSHTTPCookieStorage sharedHTTPCookieStorage] deleteCookie:cookie];
//    }
//    NSMutableDictionary *headers = [NSMutableDictionary dictionaryWithObject:@"application/json" forKey:@"Content-Type"];
//    [headers enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
//        [request addValue:obj forHTTPHeaderField:key];
//    }];
//    request.HTTPMethod = @"POST";
//    
//    NSDictionary *dictionary = @{
//        @"username": username,
//        @"password": password,
//    };
//    
//    
//    NSError *error = nil;
//    NSData *data = [NSJSONSerialization dataWithJSONObject:dictionary
//                                                   options:kNilOptions error:&error];
//    
//    if (!error) {
//        NSURLSessionUploadTask *uploadTask = [session uploadTaskWithRequest:request
//                                                                   fromData:data completionHandler:^(NSData *data,NSURLResponse *response,NSError *error) {
//            if (error != nil) {
//                NSLog(@"ERROR");
//                return;
//            }
//            
//            NSDictionary *object = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
//            [self createSession:object[@"sessionid"] status:networkStatus];
//        }];
//        
//        [uploadTask resume];
//        
//    }
//}
//
//
//- (void)logout {
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
//    NSString *string = [NSString stringWithFormat:@"%@://%@:%@/csdk-sample/SDK/login/id/%@", scheme, server, port, configuration];
////        BOOL acceptUntrustedCertificates = [[[NSUserDefaults standardUserDefaults] objectForKey:@"acceptUntrustedCertificates"] boolValue];
//    
//    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
//    NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration];
//    
//    NSURL *URL = [NSURL URLWithString:string];
//    
//    NSMutableURLRequest *request = [[NSMutableURLRequest new] initWithURL:URL];
//    request.HTTPMethod = @"DELETE";
//    
//    [_uc stopSession];
//    
//    [[session dataTaskWithRequest:request] resume];
//}
//
//- (void)didFailToStartSession:(ACBUC *)uc completionHandler:(void (^)(void))completionHandler  API_AVAILABLE(ios(13)){
//    dispatch_async(dispatch_get_main_queue(), ^{
//        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Registration error" message:@"Registration failed" preferredStyle:UIAlertControllerStyleAlert];
//        UIAlertAction * continueButton = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action){
//            [self hider:NO];
//        }];
//        [alert addAction:continueButton];
//        id rootViewController = [UIApplication sharedApplication].delegate.window.rootViewController;
//        [rootViewController presentViewController:alert animated:YES completion:nil];
//    });
//    completionHandler();
//}
//
//- (void)didLoseConnection:(ACBUC *)uc completionHandler:(void (^)(void))completionHandler  API_AVAILABLE(ios(13)){
//    [self logout];
//    dispatch_async(dispatch_get_main_queue(), ^{
//            // TODO: On loss of connection we currently choose to log in again. This should be done automatically.
//            AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
//            
//            if (!appDelegate.userWantsToBeLoggedIn)
//            {
//                return;
//            }
//            
//            UITabBarItem *accountTab = appDelegate.tabbedViewController.tabBar.items.lastObject;
//        if ((self->automaticLoginReattempts >= 2) ||
//            (self->lastReconnectionAttempt >= [NSDate timeIntervalSinceReferenceDate] - 30))
//            {
//                accountTab.badgeValue = @"Logged Out";
//            }
//            else
//            {
//                accountTab.badgeValue = @"...logging in...";
//                self->lastReconnectionAttempt = [NSDate timeIntervalSinceReferenceDate];
//                [self loginUser:NO];
//            }
//    });
//    completionHandler();
//}
//
//- (void)uc:(ACBUC *)uc willRetryConnection:(NSInteger)attemptNumber in:(NSTimeInterval)delay completionHandler:(void (^)(void))completionHandler  API_AVAILABLE(ios(13)){
//    NSLog(@"WILL RETRY CONNECTION___%ld", (long)attemptNumber);
//    completionHandler();
//}
//
//- (void)didReestablishConnection:(ACBUC *)uc completionHandler:(void (^)(void))completionHandler  API_AVAILABLE(ios(13)){
//    NSLog(@"DID REESTABLISH CONNECTION");
//    completionHandler();
//}
//
//- (void)didReceiveSystemFailure:(ACBUC *)uc completionHandler:(void (^)(void))completionHandler  API_AVAILABLE(ios(13)){
//    dispatch_async(dispatch_get_main_queue(), ^{
//        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"ERROR" message:@"System failure. Please log in again." preferredStyle:UIAlertControllerStyleAlert];
//        UIAlertAction * continueButton = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action){
//            [self logout];
//        }];
//        [alert addAction:continueButton];
//        id rootViewController = [UIApplication sharedApplication].delegate.window.rootViewController;
//        [rootViewController presentViewController:alert animated:YES completion:nil];
//    });
//    completionHandler();
//}
//
//- (void)didStartSession:(ACBUC *)uc completionHandler:(void (^)(void))completionHandler  API_AVAILABLE(ios(13)){
//    dispatch_async(dispatch_get_main_queue(), ^{
//        [self hider:NO];
//        AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
//        UITabBarItem *accountTab = appDelegate.tabbedViewController.tabBar.items.lastObject;
//        accountTab.badgeValue = nil;
//
//        self->automaticLoginReattempts = 0;
//        LoginViewController *loginViewController = appDelegate.loginViewController;
//        loginViewController.uc = self->_uc;
//        loginViewController.configuration = self->configuration;
//        // TODO - not to perform the segue if the user logged out manually, or in other words perform it only after a non-repeated login from the Login view controller. This is not causing a problem, anyway, as the segue doesn't seem to operate if the login form is not on top.
//        [loginViewController performSegueWithIdentifier:@"loginSegue" sender:self];
//    });
//    completionHandler();
//}
//
//
//- (void)URLSession:(NSURLSession *)session
//              task:(NSURLSessionTask *)task
//didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge
// completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential *))completionHandler {
//    if (challenge.protectionSpace.serverTrust == NULL) {
//        completionHandler(NSURLSessionAuthChallengeUseCredential, nil);
//    } else {
//        SecTrustRef trust = challenge.protectionSpace.serverTrust;
//        NSURLCredential *credential = [NSURLCredential credentialForTrust:trust];
//        completionHandler(NSURLSessionAuthChallengeUseCredential, credential);
//    }
//}
//@end
////#endif
#import <Foundation/Foundation.h>
#import "AuthenticationService.h"
#import "AppDelegate.h"
#import "UCClientTabbedViewController.h"
#import <UserNotifications/UserNotifications.h>

@import FCSDKiOS;

API_AVAILABLE(ios(13))
@interface AuthenticationService() {
    ACBUC *_uc;
    UIView *hider;
    NSString *server;
    NSString *configuration;
    int automaticLoginReattempts;
    NSTimeInterval lastReconnectionAttempt;
}
@end

@implementation AuthenticationService

- (void)createSession:(NSString *)sessionId status:(BOOL)networkStatus {
    if (@available(iOS 13, *)) {
        NSArray *strings = @[]; // Use literal syntax for empty array
        [ACBUC ucWithConfiguration:sessionId stunServers:strings delegate:self options:ACBUCOptions.noVoiceProcessing completionHandler:^(ACBUC *uc) {
            [uc acceptAnyCertificate:YES];
            [uc setNetworkReachable:networkStatus];

            NSNumber *useCookiesNumber = [[NSUserDefaults standardUserDefaults] objectForKey:@"useCookies"];
            uc.useCookies = [useCookiesNumber boolValue];

            [uc startSessionWithTriggerReconnect:YES completionHandler:^{
                self->_uc = uc;
            }];
        }];
    } else {
        // Fallback on earlier versions
    }
}

- (UIWindow *)getFirstWindow {
    // Get the connected scenes
    NSArray<UIScene *> *scenes = [UIApplication sharedApplication].connectedScenes.allObjects;

    // Iterate through the scenes to find the active UIWindowScene
    for (UIScene *scene in scenes) {
        if ([scene isKindOfClass:[UIWindowScene class]]) {
            UIWindowScene *windowScene = (UIWindowScene *)scene;

            // Access the windows of the UIWindowScene
            NSArray<UIWindow *> *windows = windowScene.windows;

            // Return the first window if available
            if (windows.count > 0) {
                return windows.firstObject; // Get the first window
            }
        }
    }
    
    return nil; // Return nil if no windows are found
}


- (void)hider:(BOOL)on {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (on) {
            UIWindow *window = [self getFirstWindow];
            self->hider = [[UIView alloc] initWithFrame:window.bounds];
            self->hider.alpha = 0.3f;
            self->hider.backgroundColor = [UIColor blackColor];
            UIView *view = window.subviews.firstObject;
            [view addSubview:self->hider];
        } else {
            [self->hider removeFromSuperview];
            self->hider = nil;
        }
    });
}

- (void)loginUser:(BOOL)networkStatus {
    if (networkStatus) {
        [self hider:YES];
    }

    NSString *username = [[NSUserDefaults standardUserDefaults] objectForKey:@"username"];
    NSString *password = [[NSUserDefaults standardUserDefaults] objectForKey:@"password"];
    server = [[NSUserDefaults standardUserDefaults] objectForKey:@"server"];
    NSNumber *port = [[NSUserDefaults standardUserDefaults] objectForKey:@"port"] ?: @8080; // Default to 8080 if nil
    BOOL secure = [[[NSUserDefaults standardUserDefaults] objectForKey:@"secureSwitch"] boolValue];
    NSString *scheme = secure ? @"https" : @"http";
    NSString *urlString = [NSString stringWithFormat:@"%@://%@:%@/csdk-sample/SDK/login", scheme, server, port];

    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration delegate:self delegateQueue:nil];
    NSURL *URL = [NSURL URLWithString:urlString];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:URL];
    
    // Clear existing cookies
    [[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookieAcceptPolicy:NSHTTPCookieAcceptPolicyAlways];
    for (NSHTTPCookie *cookie in [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookies]) {
        [[NSHTTPCookieStorage sharedHTTPCookieStorage] deleteCookie:cookie];
    }

    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    request.HTTPMethod = @"POST";

    NSDictionary *dictionary = @{@"username": username, @"password": password};
    NSError *error = nil;
    NSData *data = [NSJSONSerialization dataWithJSONObject:dictionary options:0 error:&error];

    if (!error) {
        NSURLSessionUploadTask *uploadTask = [session uploadTaskWithRequest:request fromData:data completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
            if (error) {
                NSLog(@"ERROR: %@", error.localizedDescription);
                return;
            }

            NSDictionary *object = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
            if (!error) {
                [self createSession:object[@"sessionid"] status:networkStatus];
            } else {
                NSLog(@"JSON Parsing Error: %@", error.localizedDescription);
            }
        }];
        [uploadTask resume];
    } else {
        NSLog(@"JSON Serialization Error: %@", error.localizedDescription);
    }
}

- (void)logout {
    NSLog(@"Starting logout - Server %@ Configuration %@", server, configuration);
    NSNumber *port = [[NSUserDefaults standardUserDefaults] objectForKey:@"port"] ?: @8080; // Default to 8080 if nil
    BOOL secure = [[[NSUserDefaults standardUserDefaults] objectForKey:@"secureSwitch"] boolValue];
    NSString *scheme = secure ? @"https" : @"http";
    NSString *urlString = [NSString stringWithFormat:@"%@://%@:%@/csdk-sample/SDK/login/id/%@", scheme, server, port, configuration];

    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration];
    NSURL *URL = [NSURL URLWithString:urlString];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:URL];
    request.HTTPMethod = @"DELETE";

    [_uc stopSession];
    [[session dataTaskWithRequest:request] resume];
}

// Handle session failure
- (void)didFailToStartSession:(ACBUC *)uc completionHandler:(void (^)(void))completionHandler API_AVAILABLE(ios(13)) {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Registration error" message:@"Registration failed" preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *continueButton = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            [self hider:NO];
        }];
        [alert addAction:continueButton];
        id rootViewController = [UIApplication sharedApplication].delegate.window.rootViewController;
        [rootViewController presentViewController:alert animated:YES completion:nil];
    });
    completionHandler();
}

// Handle connection loss
- (void)didLoseConnection:(ACBUC *)uc completionHandler:(void (^)(void))completionHandler API_AVAILABLE(ios(13)) {
    [self logout];
    dispatch_async(dispatch_get_main_queue(), ^{
        AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
        if (!appDelegate.userWantsToBeLoggedIn) {
            return;
        }

        UITabBarItem *accountTab = appDelegate.tabbedViewController.tabBar.items.lastObject;
        if ((self->automaticLoginReattempts >= 2) || (self->lastReconnectionAttempt >= [NSDate timeIntervalSinceReferenceDate] - 30)) {
            accountTab.badgeValue = @"Logged Out";
        } else {
            accountTab.badgeValue = @"...logging in...";
            self->lastReconnectionAttempt = [NSDate timeIntervalSinceReferenceDate];
            [self loginUser:NO];
        }
    });
    completionHandler();
}

// Handle retry connection
- (void)uc:(ACBUC *)uc willRetryConnection:(NSInteger)attemptNumber in:(NSTimeInterval)delay completionHandler:(void (^)(void))completionHandler API_AVAILABLE(ios(13)) {
    NSLog(@"WILL RETRY CONNECTION: %ld", (long)attemptNumber);
    completionHandler();
}

// Handle reestablished connection
- (void)didReestablishConnection:(ACBUC *)uc completionHandler:(void (^)(void))completionHandler API_AVAILABLE(ios(13)) {
    NSLog(@"DID REESTABLISH CONNECTION");
    completionHandler();
}

// Handle system failure
- (void)didReceiveSystemFailure:(ACBUC *)uc completionHandler:(void (^)(void))completionHandler API_AVAILABLE(ios(13)) {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"ERROR" message:@"System failure. Please log in again." preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *continueButton = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            [self logout];
        }];
        [alert addAction:continueButton];
        id rootViewController = [UIApplication sharedApplication].delegate.window.rootViewController;
        [rootViewController presentViewController:alert animated:YES completion:nil];
    });
    completionHandler();
}

// Handle successful session start
- (void)didStartSession:(ACBUC *)uc completionHandler:(void (^)(void))completionHandler API_AVAILABLE(ios(13)) {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self hider:NO];
        AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
        UITabBarItem *accountTab = appDelegate.tabbedViewController.tabBar.items.lastObject;
        accountTab.badgeValue = nil;

        self->automaticLoginReattempts = 0;
        LoginViewController *loginViewController = appDelegate.loginViewController;
        loginViewController.uc = self->_uc;
        loginViewController.configuration = self->configuration;
        [loginViewController performSegueWithIdentifier:@"loginSegue" sender:self];
    });
    completionHandler();
}

// Handle URL session authentication challenge
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential *))completionHandler {
    if (challenge.protectionSpace.serverTrust) {
        SecTrustRef trust = challenge.protectionSpace.serverTrust;
        NSURLCredential *credential = [NSURLCredential credentialForTrust:trust];
        completionHandler(NSURLSessionAuthChallengeUseCredential, credential);
    } else {
        completionHandler(NSURLSessionAuthChallengeUseCredential, nil);
    }
}

@end
