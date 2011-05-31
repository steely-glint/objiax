//
//  G722Codec.m
//  objiax
//
//  Created by Tim Panton on 17/05/2011.
//  Copyright 2011 phonefromhere.com. All rights reserved.
//

#import "G722Codec.h"


@implementation G722Codec
- (id) init{
    [super init];
    g722_encode_init(&encoder_st, 64000, 0);
    g722_decode_init(&decoder_st, 64000, 0);
    return self;
}

- (NSString *) getName{
    return @"G722";
}
- (NSInteger) getRate{
    return 16000;
}

- (BOOL) decode:(NSData *)wireData audioData:(NSMutableData *)audioData{
    [audioData setLength:640];
    uint8_t * wire = (uint8_t *) [wireData bytes];
    int16_t *audio = (int16_t *) [audioData mutableBytes];
    g722_decode(&decoder_st, audio, wire, 160);
    return YES;
}


- (BOOL) encode:(NSData *)audioData wireData:(NSMutableData *)wireData{
    [wireData setLength:160];
    uint8_t * wire = (uint8_t *) [wireData mutableBytes];
    int16_t *audio = (int16_t *) [audioData bytes];    
    g722_encode(&encoder_st, wire, audio, 320);
    return YES;
}
- (void)dealloc {
    // alloc'd in self
    [super dealloc];
}
@end
