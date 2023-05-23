//#import "ClientHTTPSConnectionHandler.h"
//
//#define DATA_BUFFER_SIZE 3000
//
//@interface ClientHTTPSConnectionHandler()
//    @property (nonatomic) BOOL acceptUntrustedCertificates;
//    @property (nonatomic, strong) NSMutableData *nsData;
//    @property (nonatomic, strong) id<HTTPSConnectionHandlerDelegate> receiver;
//@end
//
//@implementation ClientHTTPSConnectionHandler
//
//static NSArray* serverCertificates;
//
//
//-(id)initWithUrlString:(NSString *)urlString acceptUntrustedCertificates:(BOOL)acceptUntrustedCertificates method:(NSString*)method
//            andHeaders:(NSDictionary *)headers andPayload:(NSData *)payload
//            andNotify:(id<HTTPSConnectionHandlerDelegate>)theReceiver
//{
//	self = [super init];
//
//    self.acceptUntrustedCertificates = acceptUntrustedCertificates;
//	self.nsData = [NSMutableData dataWithCapacity:DATA_BUFFER_SIZE];
//	self.receiver = theReceiver;
//
//	NSMutableURLRequest *mutableRequest = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:urlString]];
//	[mutableRequest setHTTPBody:payload];
//	[mutableRequest setHTTPMethod:method];
//    
//	// Workaround to the serverside wrong cookie/caching policy: https://apps.ubiquity.net/jira/browse/WEBRTC-855
//    //   In summary, we don't want to send the session ID cookie from the previous login, because this
//    //   would mean we'd get the same session rather than a new one. At the same time, we can't use the
//    //   [NSMutableURLRequest setHTTPShouldHandleCookies] API because this would prevent us from storing
//    //   cookies that are returned in the response; we may need those response cookies for the websocket.
//    //   So instead we simple clear the cookie cache before sending the login request.
//	NSArray* allCookies = [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookies];
//    for (NSHTTPCookie* cookie in allCookies)
//    {
//        [[NSHTTPCookieStorage sharedHTTPCookieStorage] deleteCookie:cookie];
//    }
//    
//	[headers enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
//		[mutableRequest addValue:obj forHTTPHeaderField:key];
//	}];
//
//    NSURLSessionDataTask *dataTask = [[NSURLSession sharedSession] dataTaskWithRequest: mutableRequest completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
//        if (!error) {
//            
//            NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
//            NSLog(@"Did receive response %li", (long)[httpResponse statusCode]);
//            [self.nsData setLength:0];
//            [self.nsData appendData:data];
//            NSLog(@"Finished loading");
//            [self.receiver dataLoaded:self.nsData];
//        } else {
//            //Error handle
//            NSLog(@"Connection failed. Error - %@ %@", [error localizedDescription],
//                  [[error userInfo] objectForKey:NSURLErrorFailingURLStringErrorKey]);
//            [self.receiver errorHappened:error];
//            return;
//        }
//    }];
//    [dataTask resume];
//    
////	NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:mutableRequest delegate:self];
////#pragma unused(connection)
//
//	return self;
//}
//
//- (void)URLSession:(NSURLSession *)session
//              task:(NSURLSessionTask *)task
//didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge
// completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential *))completionHandler {
//    if (challenge.protectionSpace.serverTrust == NULL) {
//        completionHandler(NSURLSessionAuthChallengeUseCredential, nil);
//    }else {
//        SecTrustRef trust = challenge.protectionSpace.serverTrust;
//        NSURLCredential *credential = [NSURLCredential credentialForTrust:trust];
//        completionHandler(NSURLSessionAuthChallengeUseCredential, credential);
//    }
//}
//
////- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
////{
////    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
////    NSLog(@"Did receive response %li", (long)[httpResponse statusCode]);
////	[self.nsData setLength:0];
////}
//
////- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
////{
////	[self.nsData appendData:data];
////}
//
////- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
////{
////	NSLog(@"Connection failed. Error - %@ %@", [error localizedDescription],
////		  [[error userInfo] objectForKey:NSURLErrorFailingURLStringErrorKey]);
////	[self.receiver errorHappened:error];
////}
//
////- (void)connectionDidFinishLoading:(NSURLConnection *)connection
////{
////    NSLog(@"Finished loading");
////	[self.receiver dataLoaded:self.nsData];
////}
//
//// The next two methods are required for accepting any server identity (even self signed certificates) without checking them.
//// From the comments I have found it seems that the methods are only invoked if the server certificate cannot be trusted
//// by usual means (root certificates)
////- (BOOL)connection:(NSURLConnection *)connection canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace *)protectionSpace
////{
////	NSLog(@"Protection space: %@", protectionSpace.authenticationMethod);
////	if ([protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust])
////    {
////        return self.acceptUntrustedCertificates;
////    }
////
////    if ([protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodClientCertificate])
////	{
////		return YES;
////	}
////
////	return NO;
////}
//
////- (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
////{
////	if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust])
////    {
////        [challenge.sender useCredential:[NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust] forAuthenticationChallenge:challenge];
////    }
////	if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodClientCertificate])
////    {
////        NSNull *nullified = [NSNull null];
////		[challenge.sender useCredential:[NSURLCredential credentialWithIdentity: (__bridge SecIdentityRef _Nonnull)(nullified) certificates:nil persistence:NSURLCredentialPersistenceNone] forAuthenticationChallenge:challenge];
////    }
////}
//
//@end
