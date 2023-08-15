#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <AVFoundation/AVFoundation.h>
#import "InCallQualityView.h"
#import "UCClientTabbedViewController.h"
#ifdef NSFoundationVersionNumber_iOS_13_0
@import FCSDKiOS;

API_AVAILABLE(ios(13))
@interface PhoneViewController : UIViewController
    <UCConsumer, ACBClientPhoneDelegate, ACBClientCallDelegate, UITextFieldDelegate>

@property BOOL audio;
@property BOOL video;
@property BOOL isHeld;
@property id lock;
@property ACBClientCall *call;
@property AVAudioPlayer *audioPlayer;
@property AVCaptureDevicePosition currentCamera;
@property NSArray *buttonArray;
@property NSArray *buttonLabelArray;
@property NSString *lastNumber;
@property AVAudioSession *audioSession;
@property NSString *callid;

@property (weak, nonatomic) ACBClientCall *lastIncomingCall;
@property ACBVideoCaptureSetting* selectedQuality;

@property (weak, nonatomic) IBOutlet InCallQualityView *callQualityView;
@property (weak, nonatomic) IBOutlet UIButton *muteButton;
@property (weak, nonatomic) IBOutlet UIButton *settingsButton;
@property (weak, nonatomic) IBOutlet UIButton *videoButton;
@property (weak, nonatomic) IBOutlet UIButton *holdCallButton;
@property (weak, nonatomic) IBOutlet UISegmentedControl *resolutionControl;
@property (weak, nonatomic) IBOutlet UISegmentedControl *framerateControl;
@property (weak, nonatomic) IBOutlet UISwitch *autoAnswerSwitch;
@property (weak, nonatomic) IBOutlet UITextField *dialNumberField;
@property (weak, nonatomic) IBOutlet UIView *callControls;
@property (weak, nonatomic) IBOutlet UIView *dialPad;
@property (weak, nonatomic) IBOutlet UIView *settingsView;
@property (weak, nonatomic) IBOutlet UISegmentedControl *audioSelectBtn;
@property (weak, nonatomic) IBOutlet UILabel *audioSelectLbl;

@property (strong, nonatomic) IBOutlet UIView *remoteVideoView;


- (IBAction)settingsButtonPressed:(UIButton*)sender;
- (IBAction)pressDialPadKey:(UIButton*)sender;
- (IBAction) audioOutputControlChanged:(UISegmentedControl *)sender;
- (IBAction) resolutionControlChanged:(UISegmentedControl *)sender;
- (IBAction) framerateControlChanged:(UISegmentedControl *)sender;
- (IBAction)autoAnswerToggle:(UISwitch *)sender;
- (void) answerIncomingCall;
- (void) switchToInCallUI;
- (void) switchToNotInCallUI;
- (void) dial;

@end
#endif
