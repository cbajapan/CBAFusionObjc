//
//  AuthenticationService.h
//  CBAFusionObjc
//
//  Created by Cole M on 11/28/22.
//  Copyright © 2022 AliceCallsBob. All rights reserved.
//
//

//#if NSFoundationVersionNumber > 12
#ifndef AuthenticationService_h
#define AuthenticationService_h
@import FCSDKiOS;
@interface AuthenticationService : NSObject<ACBUCDelegate, NSURLSessionDelegate, NSURLSessionDelegate, NSURLSessionTaskDelegate, ACBClientPhoneDelegate>

- (void)createSession:(NSString*)sessionId status:(BOOL)networkStatus;
- (void)loginUser:(BOOL)networkStatus;
- (void)logout;

@end
//#endif
#endif /* AuthenticationService_h */
