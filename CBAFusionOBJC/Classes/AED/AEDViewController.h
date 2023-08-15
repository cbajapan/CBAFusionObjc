#import <UIKit/UIKit.h>
#import "UCClientTabbedViewController.h"
#ifdef NSFoundationVersionNumber_iOS_13_0
@import FCSDKiOS;

API_AVAILABLE(ios(13))
@interface AEDViewController : UIViewController<UCConsumer, ACBTopicDelegate, UITableViewDelegate, UITableViewDataSource>

@property (weak, nonatomic) IBOutlet UITextField *topicNameField;
@property (weak, nonatomic) IBOutlet UITextField *expiryField;

@property (weak, nonatomic) IBOutlet UITextField *messageField;

@property (weak, nonatomic) IBOutlet UITextField *dataKeyField;
@property (weak, nonatomic) IBOutlet UITextField *dataValueField;

@property (weak, nonatomic) IBOutlet UITableView *topicListView;
@property (weak, nonatomic) IBOutlet UITextView *logTextView;

@property ACBUC *uc;

@end
#endif
