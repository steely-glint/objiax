//
//  IAXFrame.m
//  objiax
//
//  Created by Tim Panton on 28/02/2010.
//  Copyright 2010 phonefromhere.com. All rights reserved.
//

#import "IAXFrameIn.h"


@implementation IAXFrameIn

@synthesize frameData;


NSString * frameTypes[]  = {@"Unknown",@"DTMF", @"Voice",@"Video",@"Control",@"Null",@"IAXControl",
	@"Text",@"Image",@"HTML",@"Comfort"
};
NSString * pcFrameSubClasses[] = {
    @"ZERO",
  	@"NEW",
	@"PING",
	@"PONG",
	@"ACK",
	@"HANGUP",
	@"REJECT",
	@"ACCEPT",
	@"AUTHREQ",
	@"AUTHREP",
	@"INVAL",
	@"LAGRQ",
	@"LAGRP",
	@"REGREQ",
	@"REGAUTH",
	@"REGACK",
	@"REGREJ",
	@"REGREL",
	@"VNAK",
	@"DPREQ",
	@"DPREP",
	@"DIAL",
	@"TXREQ",
	@"TXCNT",
	@"TXACC",
	@"TXREADY",
	@"TXREL",
	@"TXREJ",
	@"QUELCH",
	@"UNQUELCH",
	@"POKE",
	@"ReservedA",
	@"MWI",
	@"UNSUPPORT",
	@"TRANSFER",
	@"ReservedB",
	@"ReservedC",
	@"ReservedD",
    @"TXMEDIA",
    @"RTKEY",
    @"CALLTOKEN"  
};
/*1                   2                   3
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
- (uint8_t *) dataBytes{
	return (uint8_t *) [self.frameData bytes];
}

- (BOOL) isRetryFrame{
	uint8_t * data = [self dataBytes];
	return  ((data[2] & 128) != 0)?YES:NO;
}
- (BOOL) isMiniFrame {
	uint8_t * data = [self dataBytes];
	return  ((data[0] & 128) == 0)?YES:NO;
}
- (NSInteger) getSubClass {
	uint8_t * data = [self dataBytes];
	NSInteger sc =  data[11]; 
	if (sc & 0x80){
		sc = 1 << (sc&0x7f);
	} 
	return sc;
}
- (uint8_t) getIsq{
	uint8_t * data = [self dataBytes];
	return data[9];
}
- (uint8_t) getOsq {
	uint8_t * data = [self dataBytes];
	return data[8];
}

- (NSUInteger) getTimeStamp{
	uint8_t * data = [self dataBytes];
	NSUInteger ts = 0;
    if ([self isMiniFrame]){
        ts = data[2] << 8;
        ts += data[3];
    } else {
        ts = data[4] << 24;
        ts += data[5] << 16;
        ts += data[6] << 8;
        ts += data[7];
    }
	return ts;
}
- (NSInteger) getSourceCall{
	uint8_t * data = [self dataBytes];
	NSInteger ret = (((data[0] & 0x7f) << 8) + data[1]);
	return ret;
}
- (NSString *)getFrameTypeName{
    int ft = [self getFrameType];
    if ((ft > 12) || (ft < 0)){ ft = 0;}
    return [NSString stringWithFormat:@"%@ - %d",frameTypes[ft], ft];
}

-(NSString *)getFrameDescription{
    NSString *ret = [NSString stringWithFormat:@"type = %@ subclass = %@",[self getFrameTypeName], [self getSubClassName]];
    return ret;
}

- (NSInteger) getDestinationCall{
	uint8_t * data = [self dataBytes];
	NSInteger ret = (((data[2] & 0x7f) << 8) + data[3]);
	return ret;
}

- (IAXFrameTypes) getFrameType{
	uint8_t * data = [self dataBytes];
	return  data[10];
}

- (NSString *)getSubClassName{
    int ft = [self getFrameType];
    int sc = [self getSubClass];
    NSString * ms;
    
    switch (ft){
        case IAXFrameTypeIAXControl :
            if ((sc < 0) || (sc > 40)){sc = 0;}
            ms = pcFrameSubClasses[sc];
            break;
        default:
            ms = [NSString stringWithFormat:@"subclass = %d",sc];
            break;
    }
    return ms;
}
- (NSData *) getPayload{
	uint8_t * data = [self dataBytes];
	NSInteger offs = [self isMiniFrame]?4:12;
	NSInteger rlen = [self.frameData length] - offs;
	data += offs;
	NSData * ret = [NSData dataWithBytes:data length:rlen];
	return ret;
}
- (NSData *) getFrameData{
    return self.frameData;
}
- (void) dumpFrame:(NSString *) prompt {
    NSMutableString *prt = [[NSMutableString alloc] initWithString:prompt];
    [prt appendFormat:@"ts=%d ",[self getTimeStamp]];
    if ([self isMiniFrame]==YES){
        [prt appendString:@"Mini "];
        [prt appendFormat:@"s=%d ",[self getSourceCall]];
    } else {
        [prt appendFormat:@"s=%d d=%d ",[self getSourceCall],[self getDestinationCall]];
        [prt appendFormat:@"i=%d o=%d ",[self getIsq],[self getOsq]];
        [prt appendFormat:@"%@",[self isRetryFrame]==YES?@"Retry ":@""];
        [prt appendFormat:@"%@ ",[self getFrameDescription]];
    }
    [prt appendFormat:@"pl=%d\n",[[self getPayload] length]];
    NSLog(@"%@",prt);
    [prt release];
}
- (BOOL) mustSendAck{
    BOOL shouldSendAck = YES;
    if ([self getFrameType]== IAXFrameTypeIAXControl) {
        shouldSendAck = NO; // not sure I agreee but hey ho...
        switch ([self getSubClass]) {
            case IAXProtocolControlFrameTypeNEW:
            case IAXProtocolControlFrameTypeHANGUP:
            case IAXProtocolControlFrameTypeREJECT:
            case IAXProtocolControlFrameTypeACCEPT:
            case IAXProtocolControlFrameTypePONG:
            case IAXProtocolControlFrameTypeAUTHREP:
            case IAXProtocolControlFrameTypeREGREL:
            case IAXProtocolControlFrameTypeREGACK:
            case IAXProtocolControlFrameTypeREGREJ:
            case IAXProtocolControlFrameTypeTXREL:
            case IAXProtocolControlFrameTypeLAGRP:
                shouldSendAck = true;
                break;
            default:
                break;
        }
    }
    return shouldSendAck;
}
@end
