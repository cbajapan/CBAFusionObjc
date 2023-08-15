#import <Foundation/Foundation.h>
#if __IPHONE_OS_VERSION_MIN_REQUIRED >= __IPHONE_13
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
