//
//  AuthenticationService.h
//  CBAFusionObjc
//
//  Created by Cole M on 11/28/22.
//  Copyright © 2022 AliceCallsBob. All rights reserved.
//
//
#ifndef AuthenticationService_h
#define AuthenticationService_h
#ifdef NSFoundationVersionNumber_iOS_13_0
@import FCSDKiOS;

@interface AuthenticationService : NSObject<ACBUCDelegate, NSURLSessionDelegate, NSURLSessionDelegate, NSURLSessionTaskDelegate, ACBClientPhoneDelegate>

- (void)createSession:(NSString*)sessionId status:(BOOL)networkStatus;
- (void)loginUser:(BOOL)networkStatus;
- (void)logout;

@end
#endif
#endif /* AuthenticationService_h */
