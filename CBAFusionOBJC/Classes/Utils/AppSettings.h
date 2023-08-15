#import <Foundation/Foundation.h>
#ifdef NSFoundationVersionNumber_iOS_13_0
@import FCSDKiOS;

/**
    Interface to query settings made by the user through the iOS Settings app.
 */
@interface AppSettings : NSObject

/** To be called on app startup. Registers default values for all settings. */
+ (void) registerDefaults;

+ (ACBMediaDirection) preferredAudioDirection;
+ (ACBMediaDirection) preferredVideoDirection;
+ (BOOL) shouldAutoAnswer;
+ (void) toggleAutoAnswer: (BOOL) enableAutoAnswer;

@end
#endif
