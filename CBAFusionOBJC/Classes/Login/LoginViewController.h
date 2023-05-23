#import <Foundation/Foundation.h>

@class ACBUC;

API_AVAILABLE(ios(13))
@interface LoginViewController : UIViewController <UITextFieldDelegate>
@property (weak, nonatomic) IBOutlet UILabel *versionField;
@property (weak, nonatomic) IBOutlet UITextField *passwordField;
@property (weak, nonatomic) IBOutlet UITextField *userNameField;
@property (weak, nonatomic) IBOutlet UITextField *serverField;
@property (weak, nonatomic) IBOutlet UITextField *portField;
@property (weak, nonatomic) IBOutlet UISwitch *secureSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *untrustedCertificatesSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *useCookiesSwitch;
@property (weak, nonatomic) IBOutlet UIView *fieldContainerView;
@property (strong) ACBUC *uc;
@property (strong) NSString *configuration;
- (IBAction)loginPress:(id)sender;

@end
