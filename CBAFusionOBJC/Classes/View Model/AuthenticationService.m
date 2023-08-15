//
//  AuthenticationService.m
//  CBAFusionObjc
//
//  Created by Cole M on 11/28/22.
//  Copyright © 2022 AliceCallsBob. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AuthenticationService.h"
#import "AppDelegate.h"
#import "UCClientTabbedViewController.h"
#import <UserNotifications/UserNotifications.h>

#ifdef NSFoundationVersionNumber_iOS_13_0
@import FCSDKiOS;

API_AVAILABLE(ios(13))
@interface AuthenticationService()
{
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
    ///Deprecated!!!!
//        _uc = [ACBUC ucWithConfiguration:sessionId delegate:self];
    
    if (@available(iOS 13, *)) {
        [ACBUC ucWithConfiguration:sessionId delegate:self completionHandler:^(ACBUC * uc) {
            //We Need to temporarily set the delegate
            [uc.phone setDelegate:self];
            [uc setNetworkReachable:networkStatus];
            BOOL acceptUntrustedCertificates = [[[NSUserDefaults standardUserDefaults] objectForKey:@"acceptUntrustedCertificates"] boolValue];
            [uc acceptAnyCertificate:acceptUntrustedCertificates];
            NSNumber *useCookiesNumber = [[NSUserDefaults standardUserDefaults] objectForKey:@"useCookies"];
            uc.useCookies = [useCookiesNumber boolValue];
            [uc startSession];
            self->_uc = uc;
        }];
    } else {
        // Fallback on earlier versions
    }
}

- (void)hider:(BOOL)on
{
    if (on)
    {
        UIApplication *app = [UIApplication sharedApplication];
        UIWindow *window = [app.windows objectAtIndex:0];
        hider = [[UIView new] initWithFrame:window.frame];
        hider.alpha = 0.3f;
        hider.backgroundColor = [UIColor blackColor];
        UIView *view = [window.subviews objectAtIndex:0];
        [view insertSubview:hider atIndex:view.subviews.count];
    }
    else
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self->hider removeFromSuperview];
            self->hider = Nil;
        });
    }
}

- (void)loginUser:(BOOL)networkStatus {
    
    if (networkStatus)
    {
        [self hider:YES];
    }
    NSString *username = [[NSUserDefaults standardUserDefaults] objectForKey:@"username"];
    NSString *password = [[NSUserDefaults standardUserDefaults] objectForKey:@"password"];
    server             = [[NSUserDefaults standardUserDefaults] objectForKey:@"server"];
    NSNumber *port     = [[NSUserDefaults standardUserDefaults] objectForKey:@"port"];
    
    if (port == nil)
    {
        port = @8080;
    }
    
    NSNumber *secureNumber = [[NSUserDefaults standardUserDefaults] objectForKey:@"secureSwitch"];
    BOOL secure = [secureNumber boolValue];
    
    NSString *scheme = secure ? @"https" : @"http";
    
    NSString *string = [NSString stringWithFormat:@"%@://%@:%@/csdk-sample/SDK/login", scheme, server, port];
    //    NSNumber *useCookies = [[NSUserDefaults standardUserDefaults] objectForKey:@"useCookies"];
    
    //    NSNumber *acceptCertificateNumber = [[NSUserDefaults standardUserDefaults] objectForKey:@"acceptUntrustedCertificates"];
    //    BOOL acceptUntrustedCertificates = [acceptCertificateNumber boolValue];
    
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration delegate:self delegateQueue:nil];
    
    NSURL *URL = [NSURL URLWithString:string];
    
    
    NSMutableURLRequest *request = [[NSMutableURLRequest new] initWithURL:URL];
    
    NSArray* allCookies = [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookies];
    for (NSHTTPCookie* cookie in allCookies)
    {
        [[NSHTTPCookieStorage sharedHTTPCookieStorage] deleteCookie:cookie];
    }
    NSMutableDictionary *headers = [NSMutableDictionary dictionaryWithObject:@"application/json" forKey:@"Content-Type"];
    [headers enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        [request addValue:obj forHTTPHeaderField:key];
    }];
    request.HTTPMethod = @"POST";
    
    NSDictionary *dictionary = @{
        @"username": username,
        @"password": password,
    };
    
    
    NSError *error = nil;
    NSData *data = [NSJSONSerialization dataWithJSONObject:dictionary
                                                   options:kNilOptions error:&error];
    
    if (!error) {
        NSURLSessionUploadTask *uploadTask = [session uploadTaskWithRequest:request
                                                                   fromData:data completionHandler:^(NSData *data,NSURLResponse *response,NSError *error) {
            if (error != nil) {
                NSLog(@"ERROR");
                return;
            }
            
            NSLog(@"SUCCESS WITH RESPONSE %@", response);
            NSDictionary *object = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
            NSLog(@"OBJECT RECEIVED_____%@", object);
            [self createSession:object[@"sessionid"] status:networkStatus];
        }];
        
        [uploadTask resume];
        
    }
}


- (void)logout {
    NSLog(@"Starting logout - Server %@ Configuration %@", server, configuration);
    NSNumber *port = [[NSUserDefaults standardUserDefaults] objectForKey:@"port"];
    if (port == nil)
    {
        port = @8080;
    }
    
    BOOL secure = [[[NSUserDefaults standardUserDefaults] objectForKey:@"secureSwitch"] boolValue];
    NSString *scheme = secure ? @"https" : @"http";
    
    NSString *string = [NSString stringWithFormat:@"%@://%@:%@/csdk-sample/SDK/login/id/%@", scheme, server, port, configuration];
    //    BOOL acceptUntrustedCertificates = [[[NSUserDefaults standardUserDefaults] objectForKey:@"acceptUntrustedCertificates"] boolValue];
    
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration delegate:self delegateQueue:nil];
    
    NSURL *URL = [NSURL URLWithString:string];
    
    NSMutableURLRequest *request = [[NSMutableURLRequest new] initWithURL:URL];
    request.HTTPMethod = @"DELETE";
    
    [_uc stopSession];
    
    [[session dataTaskWithRequest:request] resume];
}

- (void)didFailToStartSession:(ACBUC *)uc completionHandler:(void (^)(void))completionHandler  API_AVAILABLE(ios(13)){
    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Registration error" message:@"Registration failed" preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction * continueButton = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action){
            [self hider:NO];
        }];
        [alert addAction:continueButton];
        id rootViewController = [UIApplication sharedApplication].delegate.window.rootViewController;
        [rootViewController presentViewController:alert animated:YES completion:nil];
    });
    completionHandler();
}

- (void)didLoseConnection:(ACBUC *)uc completionHandler:(void (^)(void))completionHandler  API_AVAILABLE(ios(13)){
    [self logout];
    // TODO On loss of connection we currently choose to log in again. This should be done automatically.
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    if (!appDelegate.userWantsToBeLoggedIn)
    {
        return;
    }
    
    UITabBarItem *accountTab = appDelegate.tabbedViewController.tabBar.items.lastObject;
    if ((automaticLoginReattempts >= 2) ||
        (lastReconnectionAttempt >= [NSDate timeIntervalSinceReferenceDate] - 30))
    {
        accountTab.badgeValue = @"Logged Out";
    }
    else
    {
        accountTab.badgeValue = @"...logging in...";
        lastReconnectionAttempt = [NSDate timeIntervalSinceReferenceDate];
        [self loginUser:NO];
    }
    completionHandler();
}

- (void)didReceiveSystemFailure:(ACBUC *)uc completionHandler:(void (^)(void))completionHandler  API_AVAILABLE(ios(13)){
    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"ERROR" message:@"System failure. Please log in again." preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction * continueButton = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action){
            [self logout];
        }];
        [alert addAction:continueButton];
        id rootViewController = [UIApplication sharedApplication].delegate.window.rootViewController;
        [rootViewController presentViewController:alert animated:YES completion:nil];
    });
    completionHandler();
}

- (void)didStartSession:(ACBUC *)uc completionHandler:(void (^)(void))completionHandler  API_AVAILABLE(ios(13)){
    dispatch_async(dispatch_get_main_queue(), ^{
        [self hider:NO];
        AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
        UITabBarItem *accountTab = appDelegate.tabbedViewController.tabBar.items.lastObject;
        accountTab.badgeValue = nil;

        self->automaticLoginReattempts = 0;
        LoginViewController *loginViewController = appDelegate.loginViewController;
        loginViewController.uc = self->_uc;
        loginViewController.configuration = self->configuration;
        // TODO - not to perform the segue if the user logged out manually, or in other words perform it only after a non-repeated login from the Login view controller. This is not causing a problem, anyway, as the segue doesn't seem to operate if the login form is not on top.
        [loginViewController performSegueWithIdentifier:@"loginSegue" sender:self];
    });
    completionHandler();
}


- (void)URLSession:(NSURLSession *)session
              task:(NSURLSessionTask *)task
didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge
 completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential *))completionHandler {
    if (challenge.protectionSpace.serverTrust == NULL) {
        completionHandler(NSURLSessionAuthChallengeUseCredential, nil);
    }else {
        SecTrustRef trust = challenge.protectionSpace.serverTrust;
        NSURLCredential *credential = [NSURLCredential credentialForTrust:trust];
        completionHandler(NSURLSessionAuthChallengeUseCredential, credential);
    }
}

@end
#endif
