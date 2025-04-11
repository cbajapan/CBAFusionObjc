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
