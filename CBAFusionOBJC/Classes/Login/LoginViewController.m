//#if NSFoundationVersionNumber > 12
#import "AppDelegate.h"
#import "LoginViewController.h"
#import "UCClientTabbedViewController.h"

@import FCSDKiOS;

@implementation LoginViewController

- (void)viewDidLoad
{
	AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
	appDelegate.loginViewController = self;

    [self restoreSavedFieldValues];
    
    //dismiss keyboard when user taps outside fields
    UIGestureRecognizer* tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)];
    tapGesture.cancelsTouchesInView = NO;
    [self.fieldContainerView addGestureRecognizer:tapGesture];
    
   
//    NSBundle *main = [NSBundle mainBundle];
//    NSString *resourcePath = [main pathForResource:@"Simulator" ofType:@"mp4"];
}

- (IBAction)loginPress:(id)sender
{
    [self saveFieldValues];
    
	AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    appDelegate.userWantsToBeLoggedIn = YES;
    
    [appDelegate.authenticationService loginUser: appDelegate.networkMonitor.status];
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"loginSegue"] || [segue.identifier isEqualToString:@"login2Segue"])
    {
        UCClientTabbedViewController *imView = (UCClientTabbedViewController *)segue.destinationViewController;
        imView.configuration = self.configuration;
        imView.server = [[NSUserDefaults standardUserDefaults] objectForKey:@"server"];

		imView.uc = _uc;

        [[[self view] window] setRootViewController:imView];
    }
}

- (void)handleSingleTap:(UITapGestureRecognizer *) sender
{
    [self.view endEditing:YES];
}

#pragma mark - Private Utils

- (void)saveFieldValues {
    [[NSUserDefaults standardUserDefaults] setObject:self.userNameField.text forKey:@"username"];
    [[NSUserDefaults standardUserDefaults] setObject:self.passwordField.text forKey:@"password"];
    [[NSUserDefaults standardUserDefaults] setObject:self.serverField.text   forKey:@"server"];
    [[NSUserDefaults standardUserDefaults] setObject:self.portField.text     forKey:@"port"];
    
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:self.secureSwitch.on] forKey:@"secureSwitch"];
    
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:self.untrustedCertificatesSwitch.on] forKey:@"acceptUntrustedCertificates"];
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:self.useCookiesSwitch.on] forKey:@"useCookies"];
}

- (void)restoreSavedFieldValues {
    self.versionField.text = Constants.SDK_VERSION_NUMBER;
    
    self.userNameField.text = [[NSUserDefaults standardUserDefaults] objectForKey:@"username"];
    self.passwordField.text = [[NSUserDefaults standardUserDefaults] objectForKey:@"password"];
    self.serverField.text   = [[NSUserDefaults standardUserDefaults] objectForKey:@"server"];
    
    NSNumber *port = [[NSUserDefaults standardUserDefaults] objectForKey:@"port"];
    NSString *portString = port ? [[NSString alloc] initWithFormat:@"%@", port] : @"";
    self.portField.text = portString;
    
    NSNumber *secureNumber = [[NSUserDefaults standardUserDefaults] objectForKey:@"secureSwitch"];
    BOOL secure = [secureNumber boolValue];
    [self.secureSwitch setOn:secure];
    
    NSNumber *acceptUntrustedCertificatesNumber = [[NSUserDefaults standardUserDefaults] objectForKey:@"acceptUntrustedCertificates"];
    BOOL acceptUntrustedCertificates = [acceptUntrustedCertificatesNumber boolValue];
    [self.untrustedCertificatesSwitch setOn:acceptUntrustedCertificates];
    
    NSNumber *useCookiesNumber = [[NSUserDefaults standardUserDefaults] objectForKey:@"useCookies"];
    BOOL useCookies = [useCookiesNumber boolValue];
    [self.useCookiesSwitch setOn:useCookies];
}

@end

//#endif
