#import "PhoneViewController.h"
#import "AppSettings.h"
#import <UserNotifications/UserNotifications.h>
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
    NSUUID *callIdentifier;
    NSMutableArray *provAlerts;
    UIView *previewView;
    UILabel *callIDLabel;
}

@synthesize uc;


#pragma mark - Initialization


- (UIView*)createVideoView {
    return [[UIView new] initWithFrame:CGRectZero];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.settingsView setHidden:true];
    [self.uc.phone setDelegate:self];
    //IF YOU DO NOT START THE AUDIO SESSION YOU CANNOT USE THE MANAGER PROPERLY!
    [self.uc.phone.audioDeviceManager start];
}


/// We Show Case how to use both programatic UIView's and Storyboards
- (void) setupPhone:(void (^)(void))completionHandler {
    provAlerts = [[NSMutableArray alloc] init];
    [self requestMicrophoneAndCameraPermissionFromAppSettings];
    
    // Default the audio and video to be enabled on start of call
    audioAllowed = [AppSettings preferredAudioDirection] == ACBMediaDirectionReceiveOnly || [AppSettings preferredAudioDirection] == ACBMediaDirectionSendAndReceive;
    videoAllowed = [AppSettings preferredVideoDirection] == ACBMediaDirectionReceiveOnly || [AppSettings preferredVideoDirection] == ACBMediaDirectionSendAndReceive;
    self.audio = audioAllowed;
    self.video = videoAllowed;
    [self configureResolutionOptions];
    [self configureFramerateOptions];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        self->callIDLabel = [[UILabel new] init];
        self->callIDLabel.textColor = [UIColor whiteColor];
        [self.view addSubview:self->callIDLabel];
        [self.view bringSubviewToFront:self->callIDLabel];
        self.dialNumberField.delegate = self;
        [self switchToNotInCallUI];
        
        
        // Call starts unheld
        self.isHeld = false;
        [self.autoAnswerSwitch setOn: [AppSettings shouldAutoAnswer]];
        
        //Detect tap events on the preview view - we'll use this to switch the camera
        self.currentCamera = AVCaptureDevicePositionFront;
        
        if(UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPad) {
            self.audioSelectBtn.hidden=true;
            self.audioSelectLbl.hidden=true;
        }
        
        if (@available(iOS 15, *)) {} else {
            self->previewView = [self createVideoView];
            [self.view addSubview:self->previewView];
            [self.view bringSubviewToFront:self->previewView];
            
            self->previewView.translatesAutoresizingMaskIntoConstraints = false;
            [self->previewView.topAnchor constraintEqualToAnchor:self.callControls.bottomAnchor constant:8].active = YES;
            [self->previewView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-8].active = YES;
            [self->previewView.widthAnchor constraintEqualToConstant: 70].active = YES;
            [self->previewView.heightAnchor constraintEqualToConstant: 70].active = YES;
            
            // Hide the video view (remote caller) and call controls before call created
            [self.remoteVideoView setHidden:true];
            
            [self.uc.phone setPreviewView:self->previewView];
            [self sharedViewSetupUI];
        }
    });
    completionHandler();
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
    BOOL showResolutionChoice720 = false;
    BOOL showResolutionChoice480 = false;
    NSArray *recCaptureSettings = [uc.phone recommendedCaptureSettings];
    for(ACBVideoCaptureSetting* captureSetting in recCaptureSettings) {
        if(captureSetting.resolution == ACBVideoCaptureResolution1280x720) {
            showResolutionChoice720 = true;
            showResolutionChoice480 = true;
        } else if(captureSetting.resolution == ACBVideoCaptureResolution640x480) {
            showResolutionChoice480 = true;
        }
    } if(!showResolutionChoice720) {
        [self.resolutionControl setEnabled:false forSegmentAtIndex:3];
        
    } if(!showResolutionChoice480) {
        [self.resolutionControl setEnabled:false forSegmentAtIndex:2];
    }
}

- (void) configureFramerateOptions {
    //disable 30fps unless one of the recommended settings allows it
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.framerateControl setEnabled:NO forSegmentAtIndex:1];
        [self.framerateControl setSelectedSegmentIndex:0];
        NSArray *recCaptureSettings = [self->uc.phone recommendedCaptureSettings];
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
                [_call hold];
                self.isHeld = true;
                [self.holdCallButton setTitle:@"Unhold" forState:UIControlStateNormal];
                if (@available(iOS 15, *)) {} else {
                    [self.call.remoteView setHidden: true];
                }
                
            } else {
                [_call resume];
                self.isHeld = false;
                [self.holdCallButton setTitle:@"Hold" forState:UIControlStateNormal];
                if (@available(iOS 15, *)) {} else {
                    [self.call.remoteView setHidden: false];
                }
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
        [self.call end];
        
        [self switchToNotInCallUI];
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

#pragma mark - CameraOptions

// toggles between front and rear camera capture
- (void)previewWasTapped:(UITapGestureRecognizer *)recognizer {
    self.currentCamera = (self.currentCamera == AVCaptureDevicePositionBack) ? AVCaptureDevicePositionFront : AVCaptureDevicePositionBack;
    [self.uc.phone setCamera: self.currentCamera];
}

#pragma mark - CallInstantiation

- (void) dial {
    [self setupPhone:^(void) {
        if (![self.dialNumberField.text isEqualToString:@""]) {
            
            [self.uc.phone createCallToAddress:self.dialNumberField.text
                                     withAudio:[AppSettings preferredAudioDirection]
                                         video:[AppSettings preferredVideoDirection]
                                      delegate:self
                             completionHandler:^(ACBClientCall * outboundCall) {
                self.callid = outboundCall.callId;
                [self setLabel];
                self.call = outboundCall;
                [self.call setDelegate:self];
                
                // If successs, prepare UI
                if (self.call != nil) {
                    self->callIdentifier = [[NSUUID alloc] init];
                    if (@available(iOS 15, *)) {
                        [self setupBufferViews: self.call];
                    } else {
                        self.call.remoteView = self.remoteVideoView;
                    }
                    [self setAudioEnabledState: self->audioAllowed];
                    [self setVideoEnabledState: self->videoAllowed];
                    [self switchToInCallUI];
                    dispatch_async(dispatch_get_main_queue(), ^{
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
    [self setupPhone:^(void) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [(UITabBarController*)[self parentViewController] setSelectedIndex:0];
        });
        
        ACBClientCall *newCall = self.lastIncomingCall;
        self.call = newCall;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (@available(iOS 15, *)) { } else {
                self.call.remoteView = self.remoteVideoView;
            }
            [self switchToInCallUI];
            [self requestMicrophoneAndCameraPermissionFromAppSettings];
        });
        
        [newCall answerWithAudio:[AppSettings preferredAudioDirection] andVideo:[AppSettings preferredVideoDirection] completionHandler:^{}];
    }];
}

- (void)setupBufferViews:(ACBClientCall *)call {
    if (@available(iOS 15, *)) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [call remoteBufferViewWithCompletionHandler:^(UIView * view) {
                [self.remoteVideoView removeFromSuperview];
                [self.view addSubview:view];
                [self.view bringSubviewToFront:view];
                view.translatesAutoresizingMaskIntoConstraints = false;
                [view.topAnchor constraintEqualToAnchor:self.view.topAnchor constant:0].active = YES;
                [view.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:0].active = YES;
                [view.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:0].active = YES;
                [view.bottomAnchor constraintEqualToAnchor: self.callControls.topAnchor constant:0].active = YES;
                view.frame = view.bounds;
                view.layer.masksToBounds = YES;
                self->_remoteVideoView = view;
            }];
            [call localBufferViewWithCompletionHandler:^(UIView * view) {
                
                [self.view addSubview:view];
                [self.view bringSubviewToFront:view];
                view.translatesAutoresizingMaskIntoConstraints = false;
                [view.topAnchor constraintEqualToAnchor:self.callControls.bottomAnchor constant:8].active = YES;
                [view.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-8].active = YES;
                [view.widthAnchor constraintEqualToConstant: 70].active = YES;
                [view.heightAnchor constraintEqualToConstant: 70].active = YES;
                view.frame = view.bounds;
                view.layer.masksToBounds = YES;
                self->previewView = view;
                [self sharedViewSetupUI];
            }];
            [call captureSessionWithCompletionHandler:^(AVCaptureSession * session) {}];
        });
    }
}

#pragma mark - Audio

- (void)setAudioEnabledState:(BOOL)enabledState {
    [_call enableLocalAudio:enabledState];
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
    [_call enableLocalVideo:videoState];
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
        [self->previewView setHidden:false];
        
        [self.callQualityView setHidden:false];
        [self.remoteVideoView setHidden:false];
        
        [self.holdCallButton setEnabled: true];
    });
}

- (void) switchToNotInCallUI {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.dialPad setHidden:false];
        [self->previewView setHidden:true];
        
        [self.callQualityView setHidden:true];
        [self.remoteVideoView setHidden:true];
        
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
    [call setDelegate:self];
    if (@available(iOS 15, *)) {
        [self setupBufferViews: call];
    }
    
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

- (void) call:(ACBClientCall*)call didReceiveSessionInterruption:(NSString*)message {
    if ([message isEqualToString:@"Session interrupted"]) {
        if (self.call) {
            if (_call.status == ACBClientCallStatusInCall) {
                if (!self.isHeld) {
                    [_call hold];
                    self.isHeld = true;
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self.holdCallButton setTitle:@"Unhold" forState:UIControlStateNormal];
                        if (@available(iOS 15, *)) {} else {
                            [self.call.remoteView setHidden: true];
                        }
                        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Holding call" message:@"Call was interrupted" preferredStyle:UIAlertControllerStyleAlert];
                        UIAlertAction * continueButton = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action){}];
                        [alert addAction:continueButton];
                        [self presentViewController:alert animated:YES completion:nil];
                    });
                }
            }
        }
    } else {
        // Code could be added here to do something when the interruption has ended.
    }
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

- (void)didChange:(enum ACBClientCallStatus)status call:(ACBClientCall *)call completionHandler:(void (^)(void))completionHandler {
    switch (status) {
        case ACBClientCallStatusRinging:
            [self playRingtone];
            break;
        case ACBClientCallStatusAlerting:
            break;
        case ACBClientCallStatusMediaPending:
            break;
        case ACBClientCallStatusInCall:
            self.callid = call.callId;
            [self setLabel];
            [self stopRingingIfNoOtherCallIsRinging:nil];
            break;
        case ACBClientCallStatusEnded:
            [self updateUIForEndedCall:call];
            if(callIdentifier != nil) {
                [self.call end];
                [self.lastIncomingCall end];
                dispatch_async(dispatch_get_main_queue(), ^{
                    if ([self->provAlerts count] > 0) {
                        [self->provAlerts[0] dismissViewControllerAnimated:YES completion:nil];
                    }
                    [self->provAlerts removeAllObjects];
                    [self switchToNotInCallUI];
                });
            }
            callIdentifier = nil;
            break;
        case ACBClientCallStatusSetup:
            break;
        case ACBClientCallStatusBusy:
            [self updateUIForEndedCall:call];
            if (callIdentifier != nil)
            {
                [self.call end];
                [self.lastIncomingCall end];
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
                [self.call end];
                [self.lastIncomingCall end];
            }
            callIdentifier = nil;
            break;
        case ACBClientCallStatusPreparingBufferViews:
            break;
    }
    completionHandler();
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

- (void) presentIncomingCallAlertForCall:(ACBClientCall*)call {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString* caller = call.remoteDisplayName ? call.remoteDisplayName : call.remoteAddress;
        // If we're in the background then pop up a local notification.
        if ([UIApplication sharedApplication].applicationState != UIApplicationStateActive) {
            NSString *body = [NSString stringWithFormat:@"Incoming call from %@.", caller];
            UNMutableNotificationContent *content = [[UNMutableNotificationContent alloc] init];
            content.title = [NSString localizedUserNotificationStringForKey:@"Answer"
                                                                  arguments:nil];
            content.body = [NSString localizedUserNotificationStringForKey: body
                                                                 arguments:nil];
            content.sound = [UNNotificationSound defaultSound];
            
            // 4. update application icon badge number
            content.badge = [NSNumber numberWithInteger:([UIApplication sharedApplication].applicationIconBadgeNumber + 1)];
            // Deliver the notification in five seconds.
            UNTimeIntervalNotificationTrigger *trigger = [UNTimeIntervalNotificationTrigger
                                                          triggerWithTimeInterval:5.f
                                                          repeats:NO];
            UNNotificationRequest *request = [UNNotificationRequest requestWithIdentifier:@"FiveSecond"
                                                                                  content:content
                                                                                  trigger:trigger];
            /// 3. schedule localNotification
            UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
            [center addNotificationRequest:request withCompletionHandler:^(NSError * _Nullable error) {
                if (!error) {
                    NSLog(@"add NotificationRequest succeeded!");
                }
            }];
        } else {
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
                [self.lastIncomingCall end];
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

@end
