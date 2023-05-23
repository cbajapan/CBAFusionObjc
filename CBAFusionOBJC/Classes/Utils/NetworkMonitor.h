//
//  NetworkMonitor.h
//  CBAFusionObjc
//
//  Created by Cole M on 11/28/22.
//  Copyright © 2022 AliceCallsBob. All rights reserved.
//

#ifndef NetworkMonitor_h
#define NetworkMonitor_h
#import <Network/Network.h>

@interface NetworkMonitor : NSObject

@property (nonatomic, strong) nw_path_monitor_t monitor;
@property (nonatomic, strong) dispatch_queue_t monitorQueue;
@property BOOL status;

- (void)stopNetworkMonitoring;

@end
#endif /* NetworkMonitor_h */
