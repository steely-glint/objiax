//
//  IAXFrameOut.h
//  objiax
//
//  Created by Tim Panton on 07/03/2010.
//  Copyright 2010 phonefromhere.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IAXFrameIn.h"


@interface IAXFrameOut : IAXFrameIn {
    uint32_t retryDue;
    NSInteger retryCount;
    BOOL iAmAnAck;
}

@property BOOL iAmAnAck; 

- (void) setPayload:(NSData *)fdata;

- (IAXFrameOut *) initFull;
- (IAXFrameOut *) initMini;



- (void) setTimestamp:(NSUInteger) stamp;
- (void) setSourceCall:(NSInteger) callno;
- (void) setDestinationCall:(NSInteger) callno;
- (void) setFrameType:(IAXFrameTypes) frameType;
- (void) setMiniFrame:(BOOL) yes;
- (void) setRetryFrame:(BOOL) yes;
- (void) setSubClass:(NSInteger) subclass;
- (void) setIsq:(uint8_t) s;
- (void) setOsq:(uint8_t) s;
- (BOOL) isRetryDue:(uint32_t)now;
- (BOOL) setNextRetryTime:(uint32_t)now;
@end
