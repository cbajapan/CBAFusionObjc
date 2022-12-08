#import "AccountViewController.h"
#import "ImSampleAppDelegate.h"

@interface AccountViewController ()

@end

@implementation AccountViewController
{
	UIView *hider;
}

@synthesize uc;
@synthesize server;
@synthesize configuration;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    return [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)logoutButtonAction:(id)sender
{
	ImSampleAppDelegate *appDelegate = (ImSampleAppDelegate *)[UIApplication sharedApplication].delegate;
    appDelegate.userWantsToBeLoggedIn = NO;

    [self.uc stopSession];

    hider = [[UIView alloc] initWithFrame:self.view.window.frame];
    hider.alpha = 0.3f;
    hider.backgroundColor = [UIColor blackColor];
    [self.view insertSubview:hider atIndex:self.view.subviews.count];
//    [appDelegate.connectivityManager logout];
    [appDelegate.authenticationService logout];

    [hider removeFromSuperview];
    hider = nil;
    
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard_iPhone" bundle:nil];
    UIViewController *viewController = [storyboard instantiateInitialViewController];
    [[[self view] window] setRootViewController:viewController];
}

@end
