#import <UIKit/UIKit.h>

@class ACBUC;

@protocol UCConsumer <NSObject>
    @property ACBUC *uc;
@end

@protocol UCSessionHandler <UCConsumer>
    @property NSString *configuration;
    @property NSString *server;
@end

@interface UCClientTabbedViewController : UITabBarController
    @property ACBUC *uc;
    @property NSString *server;
    @property NSString *configuration;
@end
