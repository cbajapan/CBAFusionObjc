#import <UIKit/UIKit.h>

@class ACBUC;

API_AVAILABLE(ios(13))
@protocol UCConsumer <NSObject>
    @property ACBUC *uc;
@end

@protocol UCSessionHandler <UCConsumer>
    @property NSString *configuration;
    @property NSString *server;
@end

API_AVAILABLE(ios(13))
@interface UCClientTabbedViewController : UITabBarController
    @property ACBUC *uc;
    @property NSString *server;
    @property NSString *configuration;
@end
