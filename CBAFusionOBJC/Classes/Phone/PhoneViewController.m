
//#if NSFoundationVersionNumber > 12
#import "PhoneViewController.h"
#import "AppSettings.h"
#import <UserNotifications/UserNotifications.h>
#import <AVKit/AVKit.h>
#import "AVPictureInPictureVideoCallViewController+Convenience.h"
@import MetalKit;
@import FCSDKiOS;

#pragma mark - StaticConstants

static NSString *const IMAGE_UNMUTE = @"option_unmute";
static NSString *const IMAGE_MUTE = @"option_mute";
static NSString *const IMAGE_VIDEO_ENABLE = @"option_video_enable";
static NSString *const IMAGE_VIDEO_DISABLE = @"option_video_disable";
static NSString *const RINGTONE_FILE = @"ringring";

#define CALL_BUTTON_GREEN [UIColor colorWithRed:29.0/255.0 green:158.0/255.0 blue:9.0/255.0 alpha:1.0]
#define CALL_BUTTON_RED [UIColor colorWithRed:152.0/255.0 green:0.0/255.0 blue:12.0/255.0 alpha:1.0]
#define CALL_BUTTON_GREY [UIColor colorWithRed:219.0/255.0 green:219.0/255.0 blue:219.0/255.0 alpha:1.0]

#pragma mark - Instantiation

@implementation PhoneViewController {
    bool audioEnabled;
    bool videoEnabled;
    bool audioAllowed;
    bool videoAllowed;
    NSString *callIdentifier;
    NSMutableArray *provAlerts;
    UIView *previewView;
    UIView *remoteView;
    UILabel *callIDLabel;

}

@synthesize uc;


#pragma mark - Initialization


- (UIView*)createVideoView {
    return [[UIView alloc] initWithFrame:CGRectZero];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.settingsView setHidden:true];
    self.isPipActive = NO;
    [self.uc.phone setDelegate:self];
    //IF YOU DO NOT START THE AUDIO SESSION YOU CANNOT USE THE MANAGER PROPERLY!
    [self.uc.phone.audioDeviceManager start];
    [self requestMicrophoneAndCameraPermissionFromAppSettings];
    
    [[NSNotificationCenter defaultCenter]addObserver:self
                                            selector:@selector(appMovedToForeground)
                                                name:UIApplicationDidBecomeActiveNotification
                                              object:nil];
    [[NSNotificationCenter defaultCenter]addObserver:self
                                            selector:@selector(appMovedToBackground)
                                                name:UIApplicationWillResignActiveNotification
                                              object:nil];
}


- (void)appMovedToForeground
{
//    if(_call !=NULL) [_call resumeWithCompletionHandler:^{
//        NSLog(@"foreground");
//        
//    }];
}


- (void)appMovedToBackground {
    NSLog(@"**** willResignActive");
    if (self.call != nil) {
        NSLog(@"**** willResignActive has call");
//        [self.call holdWithCompletionHandler:^{
//            NSLog(@"**** willResignActive completion");
//        }];
    }
}


- (void)setupPhone:(void (^)(void))completionHandler {
    provAlerts = [[NSMutableArray alloc] init];
    
    // Default the audio and video to be enabled on start of call
    audioAllowed = ([AppSettings preferredAudioDirection] == ACBMediaDirectionReceiveOnly ||
                    [AppSettings preferredAudioDirection] == ACBMediaDirectionSendAndReceive);
    videoAllowed = ([AppSettings preferredVideoDirection] == ACBMediaDirectionReceiveOnly ||
                    [AppSettings preferredVideoDirection] == ACBMediaDirectionSendAndReceive);
    
    self.audio = audioAllowed;
    self.video = videoAllowed;
    
    [self configureResolutionOptions];
    [self configureFramerateOptions];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        // Initialize and configure call ID label
        self->callIDLabel = [[UILabel alloc] init];
        self->callIDLabel.textColor = [UIColor whiteColor];
        [self.view addSubview:self->callIDLabel];
        [self.view bringSubviewToFront:self->callIDLabel];
        
        // Set delegate for dial number field
        self.dialNumberField.delegate = self;
        [self switchToNotInCallUI];
        
        // Call starts unheld
        self.isHeld = NO; // Use NO instead of false for Objective-C
        
        // Set auto-answer switch state
        [self.autoAnswerSwitch setOn:[AppSettings shouldAutoAnswer]];
        
        // Detect tap events on the preview view - we'll use this to switch the camera
        self.currentCamera = AVCaptureDevicePositionFront;
        
        // Hide audio selection controls on iPad
        if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPad) {
            self.audioSelectBtn.hidden = YES;
            self.audioSelectLbl.hidden = YES;
        }
        
        if (@available(iOS 15, *)) {} else {
            // Create and configure the preview view
            self->previewView = [self createVideoView];
            [self.view addSubview:self->previewView];
            [self.view bringSubviewToFront:self->previewView];
            
            self->previewView.translatesAutoresizingMaskIntoConstraints = NO;
            [NSLayoutConstraint activateConstraints:@[
                [self->previewView.topAnchor constraintEqualToAnchor:self.callControls.bottomAnchor constant:8],
                [self->previewView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-8],
                [self->previewView.widthAnchor constraintEqualToConstant:70],
                [self->previewView.heightAnchor constraintEqualToConstant:70]
            ]];
            
            // Set the preview view for the UC phone
            self.uc.phone.previewView = self->previewView;
        }
        
        // Call shared view setup UI
        [self sharedViewSetupUI];
        
        // Call the completion handler
        if (completionHandler) {
            completionHandler();
        }
    });
}


- (void) sharedViewSetupUI {
    dispatch_async(dispatch_get_main_queue(), ^{
        self->callIDLabel.translatesAutoresizingMaskIntoConstraints = false;
        [self->callIDLabel.topAnchor constraintEqualToAnchor:self.remoteVideoView.topAnchor constant:35].active = YES;
        [self->callIDLabel.leadingAnchor constraintEqualToAnchor:self.remoteVideoView.leadingAnchor constant:8].active = YES;
        [self->callIDLabel.trailingAnchor constraintEqualToAnchor:self.remoteVideoView.trailingAnchor constant:0].active = YES;
        [self->callIDLabel.heightAnchor constraintEqualToConstant:20].active = YES;
        [self.view bringSubviewToFront:self->callIDLabel];
        UITapGestureRecognizer* previewTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(previewWasTapped:)];
        [self->previewView addGestureRecognizer:previewTapRecognizer];
    });
}

- (void) requestMicrophoneAndCameraPermissionFromAppSettings {
    BOOL requestMic = ([AppSettings preferredAudioDirection] == ACBMediaDirectionSendOnly) || ([AppSettings preferredAudioDirection] == ACBMediaDirectionSendAndReceive);
    BOOL requestCam = ([AppSettings preferredVideoDirection] == ACBMediaDirectionSendOnly) || ([AppSettings preferredVideoDirection] == ACBMediaDirectionSendAndReceive);
    
    [ACBClientPhone requestMicrophoneAndCameraPermission:requestMic video:requestCam completionHandler:^{
        NSLog(@"WE HAVE PERMISSION");
    }];
}

#pragma mark - quality

- (void) configureResolutionOptions {
//    __block BOOL showResolutionChoice720 = false;
//    __block BOOL showResolutionChoice480 = false;
//    typeof(self) __weak weakSelf = self;
    [self->uc.phone setPreferredCaptureResolution:ACBVideoCaptureResolution640x480];
    [self->uc.phone setPreferredCaptureFrameRate: 30];
//    [self->uc.phone recommendedCaptureSettingsWithCompletionHandler:^(NSArray<ACBVideoCaptureSetting*>* recCaptureSettings) {
//        for(ACBVideoCaptureSetting* captureSetting in recCaptureSettings) {
//            if(captureSetting.resolution == ACBVideoCaptureResolution1280x720) {
//                showResolutionChoice720 = true;
//                showResolutionChoice480 = true;
//            } else if(captureSetting.resolution == ACBVideoCaptureResolution640x480) {
//                showResolutionChoice480 = true;
//            }
//        } if(!showResolutionChoice720) {
//            dispatch_async(dispatch_get_main_queue(), ^{
//                [weakSelf.resolutionControl setEnabled:false forSegmentAtIndex:3];
//            });
//            
//        } if(!showResolutionChoice480) {
//            dispatch_async(dispatch_get_main_queue(), ^{
//            [weakSelf.resolutionControl setEnabled:false forSegmentAtIndex:2];
//            });
//        }
//    }];
    
}

- (void) configureFramerateOptions {
    //disable 30fps unless one of the recommended settings allows it
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.framerateControl setEnabled:NO forSegmentAtIndex:1];
        [self.framerateControl setSelectedSegmentIndex:0];
        [self->uc.phone recommendedCaptureSettingsWithCompletionHandler:^(NSArray<ACBVideoCaptureSetting*>* recCaptureSettings) {
            
            dispatch_async(dispatch_get_main_queue(), ^{
                for(ACBVideoCaptureSetting* captureSetting in recCaptureSettings)
                {
                    if(captureSetting.frameRate > 20)
                    {
                        
                        [self.framerateControl setEnabled:YES forSegmentAtIndex:1];
                        [self.framerateControl setSelectedSegmentIndex:1];
                        break;
                    }
                }
            });
        }];
        
    });
}

#pragma mark - IBActions

- (IBAction) pressDialPadKey:(UIButton*)sender {
    NSString *dialPadText = [sender currentTitle];
    self.dialNumberField.text = [self.dialNumberField.text stringByAppendingString: dialPadText];
}

- (IBAction)pressDeleteKey:(id)sender {
    NSString *number = self.dialNumberField.text;
    if (number.length > 0)
    {
        self.dialNumberField.text = [number substringToIndex:number.length - 1];
    }
}

- (IBAction)dialKeyPressed:(id)sender {
    [self dial];
}

- (IBAction) holdCall:(id)sender {
    if(self.call) {
        if (_call.status == ACBClientCallStatusInCall) {
            if(!self.isHeld) {
                [_call holdWithCompletionHandler:^{
                    dispatch_async(dispatch_get_main_queue(), ^{
                        self.isHeld = true;
                        [self.holdCallButton setTitle:@"Unhold" forState:UIControlStateNormal];
                                                if (@available(iOS 15, *)) {} else {
                        [self.remoteVideoView setHidden:true];
                        [self.call.remoteView setHidden: true];
                                                }
                    });
                }];
                
            } else {
                [_call resumeWithCompletionHandler:^{
                    dispatch_async(dispatch_get_main_queue(), ^{
                        self.isHeld = false;
                        [self.holdCallButton setTitle:@"Hold" forState:UIControlStateNormal];
                                                if (@available(iOS 15, *)) {} else {
                        [self.remoteVideoView setHidden:false];
                        [self.call.remoteView setHidden: false];
                                                }
                    });
                }];
            }
        }
    }
}

- (IBAction)pressEndCall:(UIButton *)sender {
    if(self.call) {
        if ([provAlerts count] > 0) {
            [provAlerts[0] dismissViewControllerAnimated:YES completion:nil];
        }
        [provAlerts removeAllObjects];
        [self.call endWithCompletionHandler:^{
            
            
            dispatch_async(dispatch_get_main_queue(), ^{
                if (@available(iOS 15, *)) {} else {
                    [self.remoteVideoView setHidden: true];
                    [self->previewView setHidden: true];
                }
                if ([self->provAlerts count] > 0) {
                    [self->provAlerts[0] dismissViewControllerAnimated:YES completion:nil];
                }
                [self->provAlerts removeAllObjects];
                [self switchToNotInCallUI];
                if (@available(iOS 15, *)) {
                    [self removeBufferViews];
                } else {
                    [self->previewView removeFromSuperview];
                    [self->remoteView removeFromSuperview];
                    self->remoteView = nil;
                    self->previewView = nil;
                }
            });
            
            
        }];
        
        [self switchToNotInCallUI];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (@available(iOS 15, *)) {} else {
                [self.remoteVideoView setHidden: true];
                [self->previewView setHidden: true];
            }
            if ([self->provAlerts count] > 0) {
                [self->provAlerts[0] dismissViewControllerAnimated:YES completion:nil];
            }
            [self->provAlerts removeAllObjects];
            [self switchToNotInCallUI];
            if (@available(iOS 15, *)) {} else {
                [self->previewView removeFromSuperview];
                [self->remoteView removeFromSuperview];
            }
        });
    }
}

- (IBAction)pressMute:(id)sender {
    if(self.call && audioAllowed) {
        [self setAudioEnabledState:!self.audio];
    }
}

- (IBAction)pressVideo:(id)sender {
    if(self.call && videoAllowed) {
        [self setVideoEnabledState:!self.video];
    }
}

- (IBAction)settingsButtonPressed:(UIButton *)sender {
    [self.view bringSubviewToFront:self.settingsView];
    [self.settingsView isHidden] ? [self.settingsView setHidden: false] : [self.settingsView setHidden: true];
}


- (IBAction)setDefaultAudio:(UISegmentedControl *)sender {
    if(sender.selectedSegmentIndex==0) {
        [uc.phone.audioDeviceManager setDefaultAudio:ACBAudioDeviceSpeakerphone];
    } else if (sender.selectedSegmentIndex==1) {
        [uc.phone.audioDeviceManager setDefaultAudio:ACBAudioDeviceNone];
    }
}


- (IBAction) audioOutputControlChanged:(UISegmentedControl *)sender {
    if(sender.selectedSegmentIndex==0) {
        [uc.phone.audioDeviceManager setAudioDevice:ACBAudioDeviceEarpiece];
    } else if (sender.selectedSegmentIndex==1) {
        [uc.phone.audioDeviceManager setAudioDevice:ACBAudioDeviceSpeakerphone];
    }
}


- (IBAction) resolutionControlChanged:(UISegmentedControl *)sender {
    if (sender.selectedSegmentIndex == 0) {
        NSLog(@"setting resolution to auto");
        uc.phone.preferredCaptureResolution = ACBVideoCaptureResolutionAuto;
    } else if (sender.selectedSegmentIndex == 1) {
        NSLog(@"setting resolution to 352x288");
        uc.phone.preferredCaptureResolution = ACBVideoCaptureResolution352x288;
    } else if (sender.selectedSegmentIndex == 2) {
        NSLog(@"setting resolution to 640x480");
        uc.phone.preferredCaptureResolution = ACBVideoCaptureResolution640x480;
    } else if (sender.selectedSegmentIndex == 3) {
        NSLog(@"setting resolution to 1280x720");
        uc.phone.preferredCaptureResolution = ACBVideoCaptureResolution1280x720;
    }
}

- (IBAction) framerateControlChanged:(UISegmentedControl *)sender {
    if(sender.selectedSegmentIndex == 0) {
        NSLog(@"setting framerate to 20");
        uc.phone.preferredCaptureFrameRate = 20;
    } else if(sender.selectedSegmentIndex == 1) {
        NSLog(@"setting framerate to 30");
        uc.phone.preferredCaptureFrameRate = 30;
    }
}

- (IBAction)autoAnswerToggle:(UISwitch *)sender {
    self.autoAnswerSwitch.isOn ? [AppSettings toggleAutoAnswer:true] : [AppSettings toggleAutoAnswer:false];
}

- (IBAction)pipTapped:(UIButton *)sender {
    self.isPipActive = !self.isPipActive;
    [self showPipVideoCallController:_isPipActive];
//    [self showPipContentSource:_isPipActive];
}

- (IBAction)pipSelectorOptions:(UISegmentedControl *)sender {
    if(sender.selectedSegmentIndex == 0) {
        NSLog(@"Selected Remote Video For PiP Controller");
        [[NSUserDefaults standardUserDefaults] setObject:@"remote" forKey:@"PIPViewSelected"];
    } else if(sender.selectedSegmentIndex == 1) {
        NSLog(@"Selected Local Video For PiP Controller");
        [[NSUserDefaults standardUserDefaults] setObject:@"local" forKey:@"PIPViewSelected"];
    }
    [[NSUserDefaults standardUserDefaults] synchronize];
}



#pragma mark - CameraOptions

- (void)previewWasTapped:(UITapGestureRecognizer *)recognizer {
    self.currentCamera = (self.currentCamera == AVCaptureDevicePositionBack) ? AVCaptureDevicePositionFront : AVCaptureDevicePositionBack;
    __weak typeof(self) weakSelf = self;
    if(self.currentCamera == AVCaptureDevicePositionBack){
        [self.uc.phone setCamera: self.currentCamera completionHandler:^{
            typeof(self) strongSelf = weakSelf;
            if (@available(iOS 15, *)) {} else {
                strongSelf->_call.remoteView = strongSelf->previewView;
                [strongSelf.uc.phone setPreviewView:strongSelf->_remoteVideoView];
            }
        }];
    } else {
        [self.uc.phone setCamera:AVCaptureDevicePositionFront completionHandler:^{
            if (@available(iOS 15, *)) {} else {
                typeof(self) strongSelf = weakSelf;
                [strongSelf->uc.phone setPreviewView:strongSelf->previewView];
                strongSelf->_call.remoteView = strongSelf.remoteVideoView;
            }
        }];
    }
}

#pragma mark - CallInstantiation

- (void) dial {
    [self setupPhone:^(void) {
        if (![self.dialNumberField.text isEqualToString:@""]) {
            [self.uc.phone createCallToAddress:self.dialNumberField.text
                                     withAudio:[AppSettings preferredAudioDirection]
                                         video:ACBMediaDirectionSendAndReceive
                                      delegate:self
                             completionHandler:^(ACBClientCall * outboundCall) {
                self.callid = outboundCall.callId;
                [self setLabel];
                self.call = outboundCall;
                [self.call setDelegate:self];
                [self switchToInCallUI];
                
                // If successs, prepare UI
                if (self.call != nil) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        self->callIdentifier = self.call.callId;
                        if (@available(iOS 15, *)) {} else {
                            self.call.remoteView = self.remoteVideoView;
                        }
                        [self setAudioEnabledState: self->audioAllowed];
                        [self setVideoEnabledState: self->videoAllowed];
                        self.lastNumber = self.dialNumberField.text;
                        self.dialNumberField.text = @"";
                    });
                } else {
                    //recall
                    dispatch_async(dispatch_get_main_queue(), ^{
                        self.dialNumberField.text = self.lastNumber;
                    });
                }
                
            }];
        }
    }];
}

- (void)answerIncomingCall {
    ACBClientCall *newCall = self.lastIncomingCall;
    self.call = newCall;
    [self setupPhone:^(void) {
        [self switchToInCallUI];
        [self requestMicrophoneAndCameraPermissionFromAppSettings];
        if (@available(iOS 15, *)) {} else {
            self.call.remoteView = self.remoteVideoView;
        }
    }];
    self->callIdentifier = self.call.callId;
    [newCall answerWithAudio:[AppSettings preferredAudioDirection] andVideo:ACBMediaDirectionSendAndReceive completionHandler:^{}];
}

#pragma mark - Audio

- (void)setAudioEnabledState:(BOOL)enabledState {
    [_call enableLocalAudio:enabledState completionHandler:^{}];;
    audioEnabled = enabledState;
    
    [self setAudioMuteIconForAudioState:enabledState];
    
    _audio = enabledState;
}

- (void)setAudioMuteIconForAudioState:(bool)enabledState {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIImage *image = [UIImage imageNamed: (enabledState ? IMAGE_UNMUTE : IMAGE_MUTE)];
        [self->_muteButton setBackgroundImage:image forState:UIControlStateNormal];
    });
}

#pragma mark - Video

- (void)setVideoEnabledState:(BOOL)videoState {
    [_call enableLocalVideo:videoState completionHandler:^{}];;
    videoEnabled = videoState;
    
    [self setVideoMuteIcon:videoState];
    
    _video = videoState;
}

- (void)setVideoMuteIcon:(bool)videoState {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIImage *image = [UIImage imageNamed: (videoState ? IMAGE_VIDEO_ENABLE : IMAGE_VIDEO_DISABLE)];
        [self->_videoButton setBackgroundImage:image forState:UIControlStateNormal];
    });
}

- (void)DTMFButtonPressed:(UIButton *)button {
    if (button.tag >= 0 && button.tag <= 9) {
        NSLog(@"%li pressed", (long)button.tag);
        [_call playDTMFCode:[NSString stringWithFormat:@"%li",(long)button.tag] localPlayback:YES];
    } else if (button.tag == 11) {
        NSLog(@"* pressed");
        [_call playDTMFCode:@"*" localPlayback:YES];
    } else {
        NSLog(@"# pressed");
        [_call playDTMFCode:@"#" localPlayback:YES];
    }
}

#pragma mark - CallUI

- (void) switchToInCallUI {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.dialPad setHidden:true];
        [self.callQualityView setHidden:false];
        [self.holdCallButton setEnabled: true];
    });
}

- (void) switchToNotInCallUI {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.dialPad setHidden:false];
        
        [self.callQualityView setHidden:true];
        if (@available(iOS 15, *)) {} else {
            [self->previewView setHidden:true];
            [self.remoteVideoView setHidden:true];
        }
        
        [self.holdCallButton setEnabled:false];
    });
}

#pragma mark - Ringtone

- (void)playRingtone {
    NSString* filename = RINGTONE_FILE;
    NSString *path = [[NSBundle mainBundle] pathForResource:filename ofType:@"wav"];
    NSURL *fileURL = [[NSURL alloc] initFileURLWithPath: path];
    
    self.audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:fileURL error:NULL];
    self.audioPlayer.volume = 1.0;
    
    // Minus number makes ringtone play indefinitely
    self.audioPlayer.numberOfLoops = -1;
    [self.audioPlayer prepareToPlay];
    [self.audioPlayer play];
}

- (void)stopRingtone {
    if (self.audioPlayer) {
        [self.audioPlayer stop];
    }
}

#pragma mark - ACBClientDelegateMethods
-(void)phone:(ACBClientPhone *)phone received:(ACBClientCall *)call completionHandler:(void (^)(void))completionHandler {
    self.lastIncomingCall = call;
    [self playRingtone];
    
    // We need to temporarily assign ourselves as the call's delegate so that we get notified if it ends before we answer it.
    [call setDelegate: self];
    if ([AppSettings shouldAutoAnswer]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.callControls setHidden:NO];
        });
        [self stopRingtone];
        [self answerIncomingCall];
    } else {
        [self presentIncomingCallAlertForCall:call];
    }
    completionHandler();
}

-(void)phone:(ACBClientPhone *)phone didChangeSettings:(ACBVideoCaptureSetting *)settings for:(AVCaptureDevicePosition)camera completionHandler:(void (^)(void))completionHandler {
    NSLog(@"didChangeCaptureSetting - resolution=%ld frame rate= %lu camera=%ld", (long)settings.resolution, (unsigned long)settings.frameRate, (long)camera);
    completionHandler();
}
- (void)didReceiveSessionInterruption:(NSString * _Nonnull)message call:(ACBClientCall * _Nonnull)call completionHandler:(void (^ _Nonnull)(void))completionHandler; {
    if ([message isEqualToString:@"Session interrupted"]) {
        if (self.call) {
            if (_call.status == ACBClientCallStatusInCall) {
                if (!self.isHeld) {
                    [_call holdWithCompletionHandler:^{
                        
                        self.isHeld = true;
                        
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [self.holdCallButton setTitle:@"Unhold" forState:UIControlStateNormal];
                            [self.call.remoteView setHidden: true];
                            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Holding call" message:@"Call was interrupted" preferredStyle:UIAlertControllerStyleAlert];
                            UIAlertAction * continueButton = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action){}];
                            [alert addAction:continueButton];
                            [self presentViewController:alert animated:YES completion:nil];
                        });
                    }];
                }
            }
        }
    } else {
        // Code could be added here to do something when the interruption has ended.
    }
    completionHandler();
}

- (void)didReceiveCallFailureWith:(NSError *)error call:(ACBClientCall *)call completionHandler:(void (^)(void))completionHandler {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"ERROR (for call)" message:error.description preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction * continueButton = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action){}];
        [alert addAction:continueButton];
        [self presentViewController:alert animated:YES completion:nil];
    });
    completionHandler();
}

- (void)didReceiveDialFailureWith:(NSError *)error call:(ACBClientCall *)call completionHandler:(void (^)(void))completionHandler {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString* errorReason = [[error userInfo] objectForKey:NSLocalizedFailureReasonErrorKey];
        if (!errorReason) {
            errorReason = @"The call could not be connected.";
        }
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Call Failure" message:error.description preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction * continueButton = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action){}];
        [alert addAction:continueButton];
        [self presentViewController:alert animated:YES completion:nil];
        [self switchToNotInCallUI];
    });
    completionHandler();
}

- (void)didReceiveCallRecordingPermissionFailure:(NSString *)message call:(ACBClientCall *)call completionHandler:(void (^)(void))completionHandler {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"ERROR (for call)" message:message preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction * continueButton = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action){}];
        [alert addAction:continueButton];
        [self presentViewController:alert animated:YES completion:nil];
    });
    completionHandler();
}

- (void)setUpBufferView:(ACBClientCall *)call {
    [call remoteBufferViewWithCompletionHandler:^(UIView *remote) {
        if (remote) {
            self->remoteView = remote;
            [self.view addSubview:self->remoteView];
            [self.view bringSubviewToFront:self->remoteView];
            
            self->remoteView.translatesAutoresizingMaskIntoConstraints = NO;
            [self->remoteView.topAnchor constraintEqualToAnchor:self.view.topAnchor constant:0].active = YES;
            [self->remoteView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:0].active = YES;
            [self->remoteView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:0].active = YES;
            [self->remoteView.bottomAnchor constraintEqualToAnchor:self.settingsButton.topAnchor constant:0].active = YES;
        }
        
        [call localBufferViewWithCompletionHandler:^(UIView *preview) {
            if (preview) {
                self->previewView = preview;
                [self.view addSubview:self->previewView];
                [self.view bringSubviewToFront:self->previewView];
                
                self->previewView.translatesAutoresizingMaskIntoConstraints = NO;
                [self->previewView.topAnchor constraintEqualToAnchor:self.callControls.bottomAnchor constant:8].active = YES;
                [self->previewView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-8].active = YES;
                [self->previewView.widthAnchor constraintEqualToConstant:70].active = YES;
                [self->previewView.heightAnchor constraintEqualToConstant:70].active = YES;
                
                UITapGestureRecognizer *previewTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(previewWasTapped:)];
                [self->previewView addGestureRecognizer:previewTapRecognizer];
            }
        }];
    }];
}

- (void) removeBufferViews {
    [self->remoteView removeFromSuperview];
    [self->previewView removeFromSuperview];
}


- (void)didChange:(enum ACBClientCallStatus)status call:(ACBClientCall *)call completionHandler:(void (^)(void))completionHandler {
    switch (status) {
        case ACBClientCallStatusRinging:
            [self playRingtone];
            break;
        case ACBClientCallStatusAlerting:
            break;
        case ACBClientCallStatusMediaPending:
            break;
        case ACBClientCallStatusPreparingBufferViews:
            if (@available(iOS 15, *)) {
                [call captureSessionWithCompletionHandler:^(AVCaptureSession * session) {
                    self.captureSession = session;
                }];
            }
            [self setUpBufferView:call];
        case ACBClientCallStatusInCall: {
            if (@available(iOS 15, *)) {} else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.remoteVideoView setHidden: false];
                    [self->previewView setHidden: false];
                });
            }
            self.callid = call.callId;
            [self setLabel];
            [self stopRingingIfNoOtherCallIsRinging:nil];
        }
            break;
        case ACBClientCallStatusEnded:
            if(callIdentifier != nil) {
                [self.call endWithCompletionHandler:^{
                    [self updateUIForEndedCall:call];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if (@available(iOS 15, *)) {} else {
                            [self.remoteVideoView setHidden: true];
                            [self->previewView setHidden: true];
                        }
                        if ([self->provAlerts count] > 0) {
                            [self->provAlerts[0] dismissViewControllerAnimated:YES completion:nil];
                        }
                        [self->provAlerts removeAllObjects];
                        [self switchToNotInCallUI];
                        if (@available(iOS 15, *)) {
                            [self removeBufferViews];
                        } else {
                            [self->previewView removeFromSuperview];
                            [self->remoteView removeFromSuperview];
                            self->remoteView = nil;
                            self->previewView = nil;
                        }
                    });
                }];
                [self.lastIncomingCall endWithCompletionHandler:^{
                    [self updateUIForEndedCall:call];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if (@available(iOS 15, *)) {} else {
                            [self.remoteVideoView setHidden: true];
                            [self->previewView setHidden: true];
                        }
                        if ([self->provAlerts count] > 0) {
                            [self->provAlerts[0] dismissViewControllerAnimated:YES completion:nil];
                        }
                        [self->provAlerts removeAllObjects];
                        [self switchToNotInCallUI];
                        if (@available(iOS 15, *)) {} else {
                            [self->previewView removeFromSuperview];
                            [self->remoteView removeFromSuperview];
                            self->remoteView = nil;
                            self->previewView = nil;
                        }
                    });
                }];
            }
            callIdentifier = nil;
            break;
        case ACBClientCallStatusSetup:
            break;
        case ACBClientCallStatusBusy:
            [self updateUIForEndedCall:call];
            if (callIdentifier != nil)
            {
                [self.call endWithCompletionHandler:^{}];
                [self.lastIncomingCall endWithCompletionHandler:^{}];
            }
            callIdentifier = nil;
            break;
        case ACBClientCallStatusError:
            break;
        case ACBClientCallStatusNotFound:
            break;
        case ACBClientCallStatusTimedOut:
            [self updateUIForEndedCall:call];
            if(callIdentifier != nil)
            {
                [self.call endWithCompletionHandler:^{}];
                [self.lastIncomingCall endWithCompletionHandler:^{}];
            }
            callIdentifier = nil;
            break;
    }
    completionHandler();
}

- (UIImage *)snapshot:(UIView *)view
{
    UIGraphicsBeginImageContextWithOptions(view.bounds.size, YES, 0);
    [view drawViewHierarchyInRect:view.bounds afterScreenUpdates:YES];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

- (void) setLabel {
    dispatch_async(dispatch_get_main_queue(), ^{
        self->callIDLabel.text = self.callid;
    });
}

- (void)didReceiveSSRCsFor:(NSArray<NSString *> *)audioSSRCs andVideo:(NSArray<NSString *> *)videoSSRCs call:(ACBClientCall *)call completionHandler:(void (^)(void))completionHandler {
    //    dispatch_async(dispatch_get_main_queue(), ^{
    //        NSString *message = [NSString stringWithFormat:@"Received SSRC information for AUDIO %@ and VIDEO %@", audioSSRCs, videoSSRCs];
    //
    //        // Uncomment this code to show SSRC.
    //
    //        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"SSRCs" message:message preferredStyle:UIAlertControllerStyleAlert];
    //        UIAlertAction * continueButton = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action){}];
    //        [alert addAction:continueButton];
    //        [self presentViewController:alert animated:YES completion:nil];
    //    });
    completionHandler();
}

- (void)didReportInboundQualityChange:(NSInteger)inboundQuality with:(ACBClientCall *)call completionHandler:(void (^)(void))completionHandler {
    self.callQualityView.quality = inboundQuality;
    completionHandler();
}

- (void)didReceiveMediaChangeRequest:(ACBClientCall *)call completionHandler:(void (^)(void))completionHandler {
    completionHandler();
}


- (NSString *) stringifyStatus:(ACBClientCallProvisionalResponse)status {
    switch (status) {
        case ACBClientCallProvisionalResponseIgnored:
            return @"Ignored";
            break;
        case ACBClientCallProvisionalResponseRinging:
            return @"Ringing";
            break;
        case ACBClientCallProvisionalResponseBeingForwarded:
            return @"Forwarded";
            break;
        case ACBClientCallProvisionalResponseQueued:
            return @"Queued";
            break;
        case ACBClientCallProvisionalResponseSessionProgress:
            return @"Progress";
            break;
        default:
            return @"Not defined";
    }
}

- (void) alertWithProvisional:(NSString *)msg {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Provisional Response" message:msg preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction* dismissAction = [UIAlertAction actionWithTitle:@"Dismiss" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action){
            if ([self->provAlerts count] > 0) {
                [self->provAlerts removeObjectAtIndex:0]; // Myself
                if ([self->provAlerts count] > 0) {
                    UIAlertController *toDisplay = self->provAlerts[[self->provAlerts count] - 1];
                    [self presentViewController:toDisplay animated:YES completion:nil];
                }
            }
        }];
        [alert addAction:dismissAction];
        
        [self->provAlerts addObject:alert];
        if ([self->provAlerts count] == 1) {
            [self presentViewController:alert animated:YES completion:nil];
        }
    });
}
- (void)responseStatusWithDidReceive:(enum ACBClientCallProvisionalResponse)responseStatus withReason:(NSString *)reason call:(ACBClientCall *)call completionHandler:(void (^)(void))completionHandler {
    NSString *resp = [NSString stringWithFormat:@"Received Provisional %@ with additional reason %@",
                      [self stringifyStatus:responseStatus], reason];
    
    NSLog(@"%@", resp);
    
    // [self alertWithProvisional: resp];
    completionHandler();
}

- (void)didAddLocalMediaStream:(ACBClientCall * _Nonnull)call completionHandler:(void (^ _Nonnull)(void))completionHandler {
    completionHandler();
}


- (void)didAddRemoteMediaStream:(ACBClientCall * _Nonnull)call completionHandler:(void (^ _Nonnull)(void))completionHandler {
    completionHandler();
}


- (void)didChangeRemoteDisplayName:(NSString * _Nonnull)name with:(ACBClientCall * _Nonnull)call completionHandler:(void (^ _Nonnull)(void))completionHandler {
    completionHandler();
}


- (void)willReceiveMediaChangeRequest:(ACBClientCall * _Nonnull)call completionHandler:(void (^ _Nonnull)(void))completionHandler {
    completionHandler();
}


#pragma mark - TextFieldDelegateMethods

- (BOOL) textFieldShouldReturn:(UITextField *)textField {
    if (textField == self.dialNumberField) {
        [textField resignFirstResponder];
        
        [self dial];
    }
    return TRUE;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [self.view endEditing:TRUE];
    [super touchesBegan:touches withEvent:event];
}

#pragma mark - Utilities

- (NSInteger)getCurrentBadgeCount {
    return [[NSUserDefaults standardUserDefaults] integerForKey:@"badgeCount"];
}

- (void)setBadgeCount:(NSInteger)count {
    if (@available(iOS 16.0, *)) {
        [[UNUserNotificationCenter currentNotificationCenter] setBadgeCount:count withCompletionHandler:^(NSError * _Nullable error) {
            if (error) {
                NSLog(@"Error setting badge count: %@", error.localizedDescription);
            } else {
                // Store the badge count in UserDefaults
                [[NSUserDefaults standardUserDefaults] setInteger:count forKey:@"badgeCount"];
                [[NSUserDefaults standardUserDefaults] synchronize];
                NSLog(@"Badge count updated to %ld", (long)count);
            }
        }];
    } else {
        // Fallback on earlier versions
    }
}

- (void) presentIncomingCallAlertForCall:(ACBClientCall*)call {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString* caller = call.remoteDisplayName ? call.remoteDisplayName : call.remoteAddress;
        // If we're in the background then pop up a local notification.
        if ([UIApplication sharedApplication].applicationState != UIApplicationStateActive) {
            NSString *body = [NSString stringWithFormat:@"Incoming call from %@.", caller];
            UNMutableNotificationContent *content = [[UNMutableNotificationContent alloc] init];
            content.title = [NSString localizedUserNotificationStringForKey:@"Answer" arguments:nil];
            content.body = [NSString localizedUserNotificationStringForKey:body arguments:nil];
            content.sound = [UNNotificationSound defaultSound];
            
            // Update application icon badge number
            UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
            
            // Get the current badge count
            [center getNotificationSettingsWithCompletionHandler:^(UNNotificationSettings * _Nonnull settings) {
                if (settings.badgeSetting == UNNotificationSettingEnabled) {
                    // Increment the badge count

                    NSInteger newBadgeCount = [self getCurrentBadgeCount] + 1; // Increment the badge count
                    [self setBadgeCount:newBadgeCount];

                    // Get the current badge count
                    NSInteger currentBadgeCount = [self getCurrentBadgeCount];
                    if (@available(iOS 16.0, *)) {
                        [center setBadgeCount:currentBadgeCount withCompletionHandler:^(NSError * _Nullable error) {
                            if (error) {
                                NSLog(@"Error setting badge count: %@", error.localizedDescription);
                            } else {
                                NSLog(@"Badge count updated to %ld", (long)newBadgeCount);
                            }
                        }];
                    } else {
                        // Fallback on earlier versions
                    }
                }
            }];
            
            // Deliver the notification in five seconds.
            UNTimeIntervalNotificationTrigger *trigger = [UNTimeIntervalNotificationTrigger triggerWithTimeInterval:5.f repeats:NO];
            UNNotificationRequest *request = [UNNotificationRequest requestWithIdentifier:@"FiveSecond" content:content trigger:trigger];
            
            // Schedule local notification
            [center addNotificationRequest:request withCompletionHandler:^(NSError * _Nullable error) {
                if (!error) {
                    NSLog(@"add NotificationRequest succeeded!");
                } else {
                    NSLog(@"Error adding notification request: %@", error.localizedDescription);
                }
            }];
        }else {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Incoming Call" message:@"Incoming call" preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction * continueButton = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action){
                [self stopRingingIfNoOtherCallIsRinging:self.lastIncomingCall];
                [self answerIncomingCall];
                self.lastIncomingCall = nil;
                [self setAudioEnabledState:self->audioAllowed];
                [self setVideoEnabledState:self->videoAllowed];
            }];
            [alert addAction:continueButton];
            UIAlertAction * dismissButton = [UIAlertAction actionWithTitle:@"DISMISS" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action){
                NSLog(@"Rejected Call");
                [self.lastIncomingCall endWithCompletionHandler:^{}];
            }];
            [alert addAction:dismissButton];
            [self presentViewController:alert animated:YES completion:nil];
        }
    });
}

- (void) stopRingingIfNoOtherCallIsRinging:(ACBClientCall *)call {
    if (self.lastIncomingCall && (self.lastIncomingCall != call)) {
        return;
    }
    
    ACBClientCallStatus status = _call.status;
    if ((status == ACBClientCallStatusRinging) || (status == ACBClientCallStatusAlerting)) {
        return;
    }
    [self stopRingtone];
}

- (void) updateUIForEndedCall:(ACBClientCall *)call {
    if (call == self.lastIncomingCall) {
        self.lastIncomingCall = nil;
    }
    [self stopRingingIfNoOtherCallIsRinging:nil];
    [self switchToNotInCallUI];
    dispatch_async(dispatch_get_main_queue(), ^{
        self->callIDLabel.text = @"";
        [self->previewView removeFromSuperview];
        self->previewView = nil;
        self->callIDLabel = nil;
        [self->callIDLabel removeFromSuperview];
    });
}

#pragma mark - PiP
     
     - (void)showPipVideoCallController:(BOOL)show {
        if (![AVPictureInPictureController isPictureInPictureSupported]) {
            NSLog(@"PIP not Supported");
            return;
        }
        
         if (!show) {
             [self.pipController stopPictureInPicture];
             self.pipController.delegate = self;
             return;
         }

         NSString *pipViewSelected = [[NSUserDefaults standardUserDefaults] objectForKey:@"PIPViewSelected"];
         
         if (@available(iOS 15.0, *)) {
             CGSize size = [self determineSizeForOrientation:UIDevice.currentDevice.orientation minimize:NO];
             
             UIView *pipView;
             NSLog(@"SELECETED %@", pipViewSelected);
             if ([pipViewSelected isEqualToString:@"local"]) {
                 pipView = self->previewView;
             } else {
                 pipView = self->remoteView;
             }
             
             // Initialize the Picture in Picture Video Call View Controller
             AVPictureInPictureVideoCallViewController *pipVideoCallViewController =
                 [[AVPictureInPictureVideoCallViewController alloc] initWithPipView:pipView preferredContentSize:size];
             
             // Create the content source for the PIP controller
             AVPictureInPictureControllerContentSource *contentSource =
                 [[AVPictureInPictureControllerContentSource alloc] initWithActiveVideoCallSourceView:self.view contentViewController:pipVideoCallViewController];
             
             // Initialize the PIP controller
             AVPictureInPictureController *pipController = [[AVPictureInPictureController alloc] initWithContentSource:contentSource];
             
             // Use a weak reference to self to avoid retain cycles
             __weak typeof(self) weakSelf = self;
             
             // Set the PIP controller and start PIP
             [self.call setPipController:self->_pipController completionHandler:^{
                 NSLog(@"Set PIP");
                 pipController.delegate = weakSelf;
                 pipController.canStartPictureInPictureAutomaticallyFromInline = YES;
                 [pipController startPictureInPicture];
                 weakSelf.pipController = pipController;
             }];
         }
     }

     
     - (void)showPipContentSource:(BOOL)show {
         // Check if Picture-in-Picture is supported
         if (![AVPictureInPictureController isPictureInPictureSupported]) {
             NSLog(@"PIP not Supported");
             return;
         }
         
         if (@available(iOS 15.0, *)) {
             // Handle showing or stopping PiP
             if (show) {
                 AVSampleBufferDisplayLayer *sampleBufferLayer = remoteView.sampleBufferLayer;
                 if (!sampleBufferLayer) return;

                 // Ensure that we are on the main thread
                 dispatch_async(dispatch_get_main_queue(), ^{
                     // Create the content source for PiP
                     AVPictureInPictureControllerContentSource *source = [[AVPictureInPictureControllerContentSource alloc] initWithSampleBufferDisplayLayer:sampleBufferLayer playbackDelegate:self];
                     
                     // Initialize the PiP controller if it doesn't exist
                     if (!self.pipController) {
                         self.pipController = [[AVPictureInPictureController alloc] initWithContentSource:source];
                         self.pipController.canStartPictureInPictureAutomaticallyFromInline = YES;
                     } else {
                         // If PiP is already active, stop it before reusing the controller
                         if (self.pipController.isPictureInPictureActive) {
                             [self.pipController stopPictureInPicture];
                         }
                         // Update the content source if reusing the controller
                         [self.pipController setContentSource:source];
                     }

                     // Set the PiP controller in your call object
                     __weak typeof(self) weakSelf = self;
                     [self->_call setPipController:self.pipController completionHandler:^{
                         __strong typeof(weakSelf) strongSelf = weakSelf;
                         if (strongSelf) {
                             NSLog(@"PiP controller set successfully. %@", strongSelf.pipController.delegate);
                             [strongSelf.pipController startPictureInPicture];
                         }
                     }];
                 });
             } else {
                 // Stop Picture in Picture if not showing
                 if (self.pipController.isPictureInPictureActive) {
                     [self.pipController stopPictureInPicture];
                 }
             }
         }
     }



- (CGSize)determineSizeForOrientation:(UIDeviceOrientation)orientation minimize:(BOOL)minimize {
    CGFloat width = 0;
    CGFloat height = 0;
    
    CGRect screenBounds = [UIScreen mainScreen].bounds;
    CGFloat screenWidth = CGRectGetWidth(screenBounds);
    CGFloat screenHeight = CGRectGetHeight(screenBounds);
    
    switch (orientation) {
        case UIDeviceOrientationUnknown:
        case UIDeviceOrientationFaceUp:
        case UIDeviceOrientationFaceDown:
            if (screenWidth < screenHeight) {
                // Portrait
                width = minimize ? screenWidth / 6.5 : screenHeight / 4.5;
                height = width * [self getAspectRatioWithWidth:screenWidth height:screenHeight];
            } else {
                // Landscape
                width = minimize ? screenWidth / 4 : screenWidth / 3;
                height = width / [self getAspectRatioWithWidth:screenWidth height:screenHeight];
            }
            break;
        case UIDeviceOrientationPortrait:
        case UIDeviceOrientationPortraitUpsideDown:
            width = minimize ? screenWidth / 6.5 : screenHeight / 4.5;
            height = width * [self getAspectRatioWithWidth:screenWidth height:screenHeight];
            break;
        case UIDeviceOrientationLandscapeLeft:
        case UIDeviceOrientationLandscapeRight:
            width = minimize ? screenWidth / 4 : screenWidth / 3;
            height = width / [self getAspectRatioWithWidth:screenWidth height:screenHeight];
            break;
        default:
            break;
    }
    
    return CGSizeMake(width, height);
}

- (CGFloat)getAspectRatioWithWidth:(CGFloat)width height:(CGFloat)height {
    return width / height; // Implement your aspect ratio calculation logic here
}

- (CGSize)setSizeWithIsLandscape:(BOOL)isLandscape minimize:(BOOL)minimize {
    CGFloat width = 0;
    CGFloat height = 0;
    
    if (isLandscape) {
        switch (UIDevice.currentDevice.userInterfaceIdiom) {
            case UIUserInterfaceIdiomPhone:
                width = minimize ? (UIScreen.mainScreen.bounds.size.width / 4) : (UIScreen.mainScreen.bounds.size.width / 3);
                height = minimize ? (UIScreen.mainScreen.bounds.size.width / 4) / [self getAspectRatioWithWidth:UIScreen.mainScreen.bounds.size.width height:UIScreen.mainScreen.bounds.size.height] : (UIScreen.mainScreen.bounds.size.width / 3) / [self getAspectRatioWithWidth:UIScreen.mainScreen.bounds.size.width height:UIScreen.mainScreen.bounds.size.height];
                break;
            case UIUserInterfaceIdiomPad:
                width = minimize ? (UIScreen.mainScreen.bounds.size.width / 3) : (UIScreen.mainScreen.bounds.size.width / 4);
                height = minimize ? (UIScreen.mainScreen.bounds.size.width / 3) / [self getAspectRatioWithWidth:UIScreen.mainScreen.bounds.size.width height:UIScreen.mainScreen.bounds.size.height] : (UIScreen.mainScreen.bounds.size.width / 4) / [self getAspectRatioWithWidth:UIScreen.mainScreen.bounds.size.width height:UIScreen.mainScreen.bounds.size.height];
                break;
            default:
                break;
        }
    } else {
        switch (UIDevice.currentDevice.userInterfaceIdiom) {
            case UIUserInterfaceIdiomPhone:
                width = minimize ? (UIScreen.mainScreen.bounds.size.width / 6.5) : (UIScreen.mainScreen.bounds.size.height / 4.5);
                height = minimize ? (UIScreen.mainScreen.bounds.size.width / 6.5) * [self getAspectRatioWithWidth:UIScreen.mainScreen.bounds.size.width height:UIScreen.mainScreen.bounds.size.height] : (UIScreen.mainScreen.bounds.size.height / 5.5) * [self getAspectRatioWithWidth:UIScreen.mainScreen.bounds.size.width height:UIScreen.mainScreen.bounds.size.height];
                break;
            case UIUserInterfaceIdiomPad:
                width = minimize ? (UIScreen.mainScreen.bounds.size.height / 3) : (UIScreen.mainScreen.bounds.size.height / 4);
                height = minimize ? (UIScreen.mainScreen.bounds.size.height / 3) * [self getAspectRatioWithWidth:UIScreen.mainScreen.bounds.size.width height:UIScreen.mainScreen.bounds.size.height] : (UIScreen.mainScreen.bounds.size.height / 4) * [self getAspectRatioWithWidth:UIScreen.mainScreen.bounds.size.width height:UIScreen.mainScreen.bounds.size.height];
                break;
            default:
                break;
        }
    }
    
    return CGSizeMake(width, height);
}

- (void) pictureInPictureController:(AVPictureInPictureController *)pictureInPictureController failedToStartPictureInPictureWithError:(NSError *)error {
    NSLog(@"FAILED TO START PIP, %@", error);
}

-(BOOL) pictureInPictureControllerIsPlaybackPaused:(AVPictureInPictureController *)pictureInPictureController {
    return false;
}

- (void)pictureInPictureControllerWillStartPictureInPicture:(AVPictureInPictureController *)pictureInPictureController {
    NSLog(@"WILL START PIP");
}
- (void) pictureInPictureControllerDidStartPictureInPicture:(AVPictureInPictureController *)pictureInPictureController {
    NSLog(@"DID START PIP");
}

- (void)pictureInPictureController:(nonnull AVPictureInPictureController *)pictureInPictureController didTransitionToRenderSize:(CMVideoDimensions)newRenderSize {
    
}


- (void)pictureInPictureController:(nonnull AVPictureInPictureController *)pictureInPictureController setPlaying:(BOOL)playing {
    
}


- (void)pictureInPictureController:(nonnull AVPictureInPictureController *)pictureInPictureController skipByInterval:(CMTime)skipInterval completionHandler:(nonnull void (^)(void))completionHandler {
    
}


- (CMTimeRange)pictureInPictureControllerTimeRangeForPlayback:(nonnull AVPictureInPictureController *)pictureInPictureController {
    // Define the start time and duration for the time range
    CMTime startTime = CMTimeMakeWithSeconds(0.0, 600); // Start at 0 seconds, with a timescale of 600
    CMTime duration = CMTimeMakeWithSeconds(60.0, 600); // Duration of 60 seconds
    
    // Create the time range
    CMTimeRange timeRange = CMTimeRangeMake(startTime, duration);
    
    return timeRange;
}


-(void) pictureInPictureControllerWillStopPictureInPicture:(AVPictureInPictureController *)pictureInPictureController {
    
    [self.view addSubview:self->remoteView];
    
    [self->remoteView.topAnchor constraintEqualToAnchor:self.view.topAnchor].active = YES;
    [self->remoteView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor].active = YES;
    [self->remoteView.bottomAnchor constraintEqualToAnchor:self.callControls.topAnchor].active = YES;
    [self->remoteView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor].active = YES;
    
    [self.view addSubview:self->previewView];
    [self.view bringSubviewToFront:self->previewView];
    
    self->previewView.translatesAutoresizingMaskIntoConstraints = NO;
    
    [self->previewView.topAnchor constraintEqualToAnchor:self.callControls.bottomAnchor constant:8].active = YES;
    [self->previewView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-8].active = YES;
    [self->previewView.widthAnchor constraintEqualToConstant:70].active = YES;
    [self->previewView.heightAnchor constraintEqualToConstant:70].active = YES;
    
    UITapGestureRecognizer *previewTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(previewWasTapped:)];
    [self->previewView addGestureRecognizer:previewTapRecognizer];
}

- (void)encodeWithCoder:(nonnull NSCoder *)coder {
    
}

- (void)preferredContentSizeDidChangeForChildContentContainer:(nonnull id<UIContentContainer>)container {
    
}

- (CGSize)sizeForChildContentContainer:(nonnull id<UIContentContainer>)container withParentContainerSize:(CGSize)parentSize {
    return container.preferredContentSize;
}

- (void)systemLayoutFittingSizeDidChangeForChildContentContainer:(nonnull id<UIContentContainer>)container {
    
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(nonnull id<UIViewControllerTransitionCoordinator>)coordinator {
    
}

- (void)willTransitionToTraitCollection:(nonnull UITraitCollection *)newCollection withTransitionCoordinator:(nonnull id<UIViewControllerTransitionCoordinator>)coordinator {
    
}

- (void)didUpdateFocusInContext:(nonnull UIFocusUpdateContext *)context withAnimationCoordinator:(nonnull UIFocusAnimationCoordinator *)coordinator {
    
}

- (void)setNeedsFocusUpdate {
    
}

- (BOOL)shouldUpdateFocusInContext:(nonnull UIFocusUpdateContext *)context {
    return NO;
}

- (void)updateFocusIfNeeded {
    
}
@end
