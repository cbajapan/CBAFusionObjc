//
//  NetworkMonitor.m
//  CBAFusionObjc
//
//  Created by Cole M on 11/28/22.
//  Copyright © 2022 AliceCallsBob. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Network/Network.h>
#import "NetworkMonitor.h"

@implementation NetworkMonitor



- (instancetype)init {
    self = [super init];
    [[NSNotificationCenter defaultCenter] addObserver:self
        selector:@selector(networkStatus:)
        name:@"network-monitor-notification"
        object:nil];
    dispatch_queue_attr_t attrs = dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL, QOS_CLASS_UTILITY, DISPATCH_QUEUE_PRIORITY_DEFAULT);
    self.monitorQueue = dispatch_queue_create("network-monitor-queue", attrs);
    
    if (@available(iOS 12.0, *)) {
        self.monitor = nw_path_monitor_create();
        [self startNetworkMonitoring];
    } else {
        // Fallback on earlier versions
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)startNetworkMonitoring
{
    dispatch_queue_attr_t attrs = dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL, QOS_CLASS_UTILITY, DISPATCH_QUEUE_PRIORITY_DEFAULT);
    self.monitorQueue = dispatch_queue_create("network-monitor-queue", attrs);
    
    if (@available(iOS 12.0, *)) {
        self.monitor = nw_path_monitor_create();
        nw_path_monitor_set_queue(self.monitor, self.monitorQueue);
        nw_path_monitor_set_update_handler(self.monitor, ^(nw_path_t _Nonnull path) {
            nw_path_status_t status = nw_path_get_status(path);
            BOOL isWiFi = nw_path_uses_interface_type(path, nw_interface_type_wifi);
            BOOL isCellular = nw_path_uses_interface_type(path, nw_interface_type_cellular);
            BOOL isEthernet = nw_path_uses_interface_type(path, nw_interface_type_wired);
            BOOL isExpensive = nw_path_is_expensive(path);
            BOOL hasIPv4 = nw_path_has_ipv4(path);
            BOOL hasIPv6 = nw_path_has_ipv6(path);
            BOOL hasNewDNS = nw_path_has_dns(path);
            BOOL satisfied = nw_path_status_satisfied;
            
            NSDictionary *userInfo = @{
                                        @"isWiFi" : @(isWiFi),
                                        @"isCellular" : @(isCellular),
                                        @"isEthernet" : @(isEthernet),
                                        @"status" : @(status),
                                        @"isExpensive" : @(isExpensive),
                                        @"hasIPv4" : @(hasIPv4),
                                        @"hasIPv6" : @(hasIPv6),
                                        @"hasNewDNS" : @(hasNewDNS),
                                        @"satisfied" : @(satisfied)
                                     };
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [NSNotificationCenter.defaultCenter postNotificationName:@"network-monitor-notification" object:nil userInfo:userInfo];
            });
        });
        
        nw_path_monitor_start(self.monitor);
    } else {
        // Fallback on earlier versions
    }
}

- (void)stopNetworkMonitoring
{
    if (@available(iOS 12.0, *)) {
        nw_path_monitor_cancel(self.monitor);
    } else {
        // Fallback on earlier versions
    }
}

- (void) networkStatus:(NSNotification *) notification {
    BOOL status = notification.userInfo[@"satisfied"];
//    NSLog(@"STATUS_IS_SATISFIED? - %i", status);
    self.status = status;
}


@end
