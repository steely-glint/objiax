//
//  IAXFrameOut.m
//  objiax
//
//  Created by Tim Panton on 07/03/2010.
//  Copyright 2010 phonefromhere.com. 

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
#import "IAXFrameOut.h"


@implementation IAXFrameOut
@synthesize iAmAnAck;
/*

Field descriptions:

'F' bit

This bit specifies whether or not the frame is a Full Frame.  If
the 'F' bit is set to 1, the frame is a Full Frame.  If it is set
to 0, it is not a Full Frame.

Source call number

This 15-bit value specifies the call number the transmitting
client uses to identify this call.  The source call number for an
active call MUST NOT be in use by another call on the same client.
Call numbers MAY be reused once a call is no longer active, i.e.,
either when there is positive acknowledgment that the call has
been destroyed or when all possible timeouts for the call have
expired.

'R' bit

This bit specifies whether or not the frame is being
retransmitted.  If the 'R' bit is set to 0, the frame is being
transmitted for the first time.  If it is set to 1, the frame is
being retransmitted.  IAX does not specify a retransmit timeout;
this is left to the implementor.

Destination call number

This 15-bit value specifies the call number the transmitting
client uses to reference the call at the remote peer.  This number
is the same as the remote peer's source call number.  The
destination call number uniquely identifies a call on the remote
peer.  The source call number uniquely identifies the call on the
local peer.

Time-stamp

The time-stamp field contains a 32-bit time-stamp maintained by an
IAX peer for a given call.  The time-stamp is an incrementally
increasing representation of the number of milliseconds since the
first transmission of the call.

OSeqno

The 8-bit OSeqno field is the outbound stream sequence number.
Upon initialization of a call, its value is 0.  It increases
incrementally as Full Frames are sent.  When the counter
overflows, it silently resets to 0.



Spencer, et al.               Informational                    [Page 43]

RFC 5456         IAX: Inter-Asterisk eXchange Version 2    February 2010


ISeqno

The 8-bit ISeqno field is the inbound stream sequence number.
Upon initialization of a call, its value is 0.  It increases
incrementally as Full Frames are received.  At any time, the
ISeqno of a call represents the next expected inbound stream
sequence number.  When the counter overflows, it silently resets
to 0.

Frametype

The Frametype field identifies the type of message carried by the
frame.  See Section 8.2 for more information.

'C' bit

This bit determines how the remaining 7 bits of the Subclass field
are coded.  If the 'C' bit is set to 1, the Subclass value is
interpreted as a power of 2.  If it is not set, the Subclass value
is interpreted as a simple 7-bit unsigned integer.

1                   2                   3
0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|F|     Source Call Number      |R|   Destination Call Number   |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|                            time-stamp                         |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|    OSeqno     |    ISeqno     |   Frame Type  |C|  Subclass   |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|                                                               |
:                             Data                              :
|                                                               |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
*/

int retryintervals [] = {100,200,400,800,1600,3200};

- (uint8_t *) dataBytes{
	return (uint8_t *) [self.frameData mutableBytes];
}
- (IAXFrameOut *) initFull {
	frameData = [[NSMutableData alloc] initWithLength:12];
	[self setMiniFrame:NO];
    retryCount =-1;
    iAmAnAck = NO;
    return self;
}
- (IAXFrameOut *) initMini {
	frameData = [[NSMutableData alloc] initWithCapacity:164];
    [((NSMutableData *)frameData)	setLength:4];
     [self setMiniFrame:YES];
    return self;
}
- (void) setTimestamp:(NSUInteger) stamp {
	uint8_t * data = [self dataBytes];
    if ([self isMiniFrame]){
        stamp = 0xffff & stamp;
        data[2] = 0xff &  (stamp >> 8);
        data[3] = 0xff & (stamp);
    } else {
        data[4] = 0xff & (stamp >> 24);
        data[5] = 0xff & (stamp >> 16);
        data[6] = 0xff & (stamp >> 8);
        data[7] = 0xff & (stamp);
    }

}

- (void) setSourceCall:(NSInteger) callno{
	uint8_t * data = [self dataBytes];
	data [0] = data [0] | (0x7f & (callno >> 8));
	data [1] = 0xff & callno;
}


- (void) setDestinationCall:(NSInteger) callno{
	uint8_t * data = [self dataBytes];
	data [2] = data [2] | (0x7f & (callno >> 8));
	data [3] = 0xff & callno;
}


- (void) setFrameType:(IAXFrameTypes) ftype{
	uint8_t * data = [self dataBytes];
	data[10] = (0xff) & ftype;
}
- (void) setMiniFrame:(BOOL) yes{
	uint8_t * data = [self dataBytes];
	uint8_t bit = yes ? 0:128;
	data [0] = (data[0] & 0x7f) | bit;
}


- (void) setRetryFrame:(BOOL) yes {
	uint8_t * data = [self dataBytes];
	uint8_t bit = yes ? 128:0;
	data [2] = (data[2] & 0x7f) | bit;
}


- (void) setSubClass:(NSInteger) subclass{
	uint8_t sc;
	uint32_t bit;
	if (subclass > 127){
		for (int bitno=31; bitno >=0; bitno--){
			bit = 1 << bitno;
			if (subclass & bit){
				sc = 0x80 | bitno;
				break;
			}
		}
	} else {
        sc = (0x7f & subclass);
    }
	uint8_t * data = [self dataBytes];
	data[11] = sc;
}

- (void) setIsq:(uint8_t) sq{
	uint8_t * data = [self dataBytes];
	data[9] = 0xff & sq;
}

- (void) setOsq:(uint8_t) sq{
	uint8_t * data = [self dataBytes];
	data[8] = sq;
}


- (void) setPayload:(NSData *)fdata{
	NSInteger offs = [self isMiniFrame]?4:12;
    [((NSMutableData *)frameData) setLength:offs];
    [((NSMutableData *)frameData) appendData:fdata];
}

- (BOOL) isRetryDue:(uint32_t)now{
    
    BOOL ret = (now > retryDue)?YES:NO;

    return ret;
    
}
- (BOOL) setNextRetryTime:(uint32_t)now{
    BOOL ret =NO;
    if (retryCount < 6){
        retryCount++;
        [self setRetryFrame:YES];
        retryDue = now + retryintervals[retryCount];
        NSLog(@"Retry %d for %d due at %d",retryCount,[self getOsq],retryDue);
        ret = YES;
    }
    return ret;
}
- (void) dealloc{

    [frameData release];

    [super dealloc];
}

@end
