//#if NSFoundationVersionNumber > 12
#import <UIKit/UIKit.h>
#import "AppDelegate.h"


int main(int argc, char *argv[])
{
    @autoreleasepool {
        if (@available(iOS 13, *)) {
            return UIApplicationMain(argc, argv, nil, NSStringFromClass([AppDelegate class]));
        }
    }
}
//
//#else
//#import <UIKit/UIKit.h>
//#import "AppDelegate.h"
//
//int main(int argc, char *argv[])
//{
//    @autoreleasepool {
//        return UIApplicationMain(argc, argv, nil, NSStringFromClass([AppDelegate class]));
//    }
//}
//#endif
