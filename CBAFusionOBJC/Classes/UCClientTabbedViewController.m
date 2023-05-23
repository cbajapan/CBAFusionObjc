#import "UCClientTabbedViewController.h"
#import "AppDelegate.h"

@implementation UCClientTabbedViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    return [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

	AppDelegate *app = (AppDelegate *)[UIApplication sharedApplication].delegate;
	app.tabbedViewController = self;

    // Custom initialization
    NSEnumerator *controllers = self.viewControllers.objectEnumerator;
    id object;
    while (object = [controllers nextObject])
    {
        NSLog(@"Initialise view controller");
        if ([object conformsToProtocol:@protocol(UCConsumer)])
        {
            NSObject<UCConsumer> *view = object;
            view.uc = _uc;
			if ([object conformsToProtocol:@protocol(UCSessionHandler)])
			{
				NSObject<UCSessionHandler> *sessionView = object;
				sessionView.configuration = _configuration;
				sessionView.server = _server;
			}
        }
        
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    NSLog(@"TABBED SEGUE");
}

-(void)dataLoaded:(NSData *)nsData withTag:(int)tag {
    NSLog(@"Logged out");
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void)errorWithCode:(NSInteger)code message:(NSString *)message
{
    // TODO
}

-(void)connectionCreated
{
    // TODO
}

@end
