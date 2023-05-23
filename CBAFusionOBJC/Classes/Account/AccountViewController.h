#import <UIKit/UIKit.h>
#import "UCClientTabbedViewController.h"

@interface AccountViewController : UIViewController<UCSessionHandler>

- (IBAction)logoutButtonAction:(id)sender;

@end
