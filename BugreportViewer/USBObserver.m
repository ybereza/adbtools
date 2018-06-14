//
//  USBObserver.m
//  BugreportViewer
//
//  Created by Yury Bereza on 13/06/2018.
//  Copyright © 2018 Yury Bereza. All rights reserved.
//

#import "USBObserver.h"

#include <IOKit/IOKitLib.h>
#include <IOKit/usb/IOUSBLib.h>

@interface USBObserver()

@property (assign, nonatomic) BOOL subscribed;
@property (assign, nonatomic) BOOL connected;

@end

static void deviceConnected(void *refCon, io_iterator_t iterator);
static void deviceDisconnected(void *refCon, io_iterator_t iterator);

@implementation USBObserver

@synthesize observable = _observable;

- (void)setObservable:(id<USBObservervable>)observable {
    _observable = observable;
    if (!self.subscribed) {
        [self listenUSB];
    }
}

- (id<USBObservervable>)observable {
    return _observable;
}

- (void)deviceConnected {
    self.connected = YES;
    if (self.observable) {
        [self.observable onDeviceConnected];
    }
}

- (void)deviceDisconnected {
    self.connected = NO;
    if (self.observable) {
        [self.observable onDeviceDisconnected];
    }
}

- (void)listenUSB {
    io_iterator_t  portIterator = 0;
    CFMutableDictionaryRef matchingDict = IOServiceMatching(kIOUSBDeviceClassName);
    IONotificationPortRef notifyPort = IONotificationPortCreate(kIOMasterPortDefault);
    CFRunLoopSourceRef runLoopSource = IONotificationPortGetRunLoopSource(notifyPort);
    CFRunLoopRef runLoop = CFRunLoopGetCurrent();
    
    CFRunLoopAddSource(runLoop, runLoopSource, kCFRunLoopDefaultMode);
    CFRetain(matchingDict);
    
    kern_return_t returnCode = IOServiceAddMatchingNotification( notifyPort, kIOMatchedNotification, matchingDict, deviceConnected,
                                                                 (__bridge void*)self, &portIterator);
    
    if ( returnCode == KERN_SUCCESS)
    {
        deviceConnected((__bridge void*)self, portIterator);
    }
    
    returnCode = IOServiceAddMatchingNotification( notifyPort, kIOTerminatedNotification, matchingDict, deviceDisconnected,
                                                  (__bridge void*)self, &portIterator);
    
    if (returnCode == KERN_SUCCESS)
    {
        deviceDisconnected((__bridge void*)self, portIterator);
    }
    
    self.subscribed = YES;
}

@end

void deviceConnected(void *refCon, io_iterator_t iterator)
{
    USBObserver* observer = (__bridge USBObserver*)refCon;
    kern_return_t  returnCode = KERN_FAILURE;
    io_object_t  usbDevice;
    
    while (( usbDevice = IOIteratorNext(iterator)))
    {
        io_name_t name;
        
        returnCode = IORegistryEntryGetName( usbDevice, name );
        
        if ( returnCode != KERN_SUCCESS )
        {
            break;
        }
    }
    if (returnCode == KERN_SUCCESS) {
        [observer deviceConnected];
    }
}

void deviceDisconnected(void *refCon, io_iterator_t iterator)
{
    USBObserver* observer = (__bridge USBObserver*)refCon;
    kern_return_t    returnCode = KERN_FAILURE;
    io_object_t      usbDevice;
    
    while ((usbDevice = IOIteratorNext(iterator)))
    {
        returnCode = IOObjectRelease(usbDevice);
        
        if ( returnCode != kIOReturnSuccess )
        {
            NSLog(@"Error releasing device");
        }
    }
    
    if (returnCode == KERN_SUCCESS) {
        [observer deviceDisconnected];
    }

}
