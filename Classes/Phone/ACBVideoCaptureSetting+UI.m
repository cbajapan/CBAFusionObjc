#import "ACBVideoCaptureSetting+UI.h"

@implementation ACBVideoCaptureSetting (UI)

- (NSString*) uiString
{
    NSString* resolutionString;
    switch (self.resolution)
    {
        case ACBVideoCaptureResolutionAuto:     return @"Auto"; break;
        case ACBVideoCaptureResolution352x288:  resolutionString = @"352x288"; break;
        case ACBVideoCaptureResolution640x480:  resolutionString = @"640x480"; break;
        case ACBVideoCaptureResolution1280x720: resolutionString = @"1280x720"; break;
        default: resolutionString = @"ERROR";
    }
    
    return [NSString stringWithFormat:@"%@ @ %lufps", resolutionString, (unsigned long)self.frameRate];
}

@end
