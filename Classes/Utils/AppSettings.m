#import "AppSettings.h"

#define KEY_AUDIO_DIRECTION @"acb.audio.direction"
#define KEY_VIDEO_DIRECTION @"acb.video.direction"
#define KEY_AUTO_ANSWER @"acb.auto.answer"

#define VALUE_SEND_AND_RECEIVE  @"SendAndReceive"
#define VALUE_SEND_ONLY         @"SendOnly"
#define VALUE_RECEIVE_ONLY      @"ReceiveOnly"
#define VALUE_NONE              @"None"

@implementation AppSettings

+ (void) registerDefaults
{
    NSDictionary* defaults = @{KEY_AUDIO_DIRECTION:VALUE_SEND_AND_RECEIVE,
                               KEY_VIDEO_DIRECTION:VALUE_SEND_AND_RECEIVE,
                               KEY_AUTO_ANSWER:@NO};
    [[NSUserDefaults standardUserDefaults] registerDefaults:defaults];
}

+ (ACBMediaDirection) mediaDirectionForString:(NSString*)string
{
    if ([string isEqual:VALUE_SEND_AND_RECEIVE])    return ACBMediaDirectionSendAndReceive;
    else if ([string isEqual:VALUE_SEND_ONLY])      return ACBMediaDirectionSendOnly;
    else if ([string isEqual:VALUE_RECEIVE_ONLY])   return ACBMediaDirectionReceiveOnly;
    else if ([string isEqual:VALUE_NONE])           return ACBMediaDirectionNone;
    else /* default */                              return ACBMediaDirectionSendAndReceive;
}

+ (ACBMediaDirection) preferredAudioDirection
{
    NSString* audioPref = [[NSUserDefaults standardUserDefaults] valueForKey:KEY_AUDIO_DIRECTION];
    return [self mediaDirectionForString:audioPref];
}

+ (ACBMediaDirection) preferredVideoDirection
{
    NSString* videoPref = [[NSUserDefaults standardUserDefaults] valueForKey:KEY_VIDEO_DIRECTION];
    return [self mediaDirectionForString:videoPref];
}

+ (BOOL) shouldAutoAnswer
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:KEY_AUTO_ANSWER];
}

+ (void) toggleAutoAnswer: (BOOL) enableAutoAnswer
{
    [[NSUserDefaults standardUserDefaults] setBool:enableAutoAnswer forKey:KEY_AUTO_ANSWER];
}

@end
