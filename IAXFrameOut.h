//
//  IAXFrameOut.h
//  objiax
//
//  Created by Tim Panton on 07/03/2010.
//  Copyright 2010 phonefromhere.com. 
//
/* Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 */
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
