//
//  GSM610Codec.m
//  objiax
//
//  Created by Tim Panton on 17/05/2011.
//  Copyright 2011 phonefromhere.com. All rights reserved.
//

#import "GSM610Codec.h"


@implementation GSM610Codec
- (id) init{
    [super init];
    encoder_st = gsm_create();
    decoder_st = gsm_create();
    return self;
}

- (NSString *) getName{
    return @"GSM";
}
- (NSInteger) getRate{
    return 8000;
}

- (BOOL) decode:(NSData *)wireData audioData:(NSMutableData *)audioData{
    [audioData setLength:320];
    uint8_t * wire = (uint8_t *) [wireData bytes];
    int16_t *audio = (int16_t *) [audioData mutableBytes];
    gsm_decode(decoder_st, wire, audio);
    return YES;
}


- (BOOL) encode:(NSData *)audioData wireData:(NSMutableData *)wireData{
    [wireData setLength:33];
    uint8_t * wire = (uint8_t *) [wireData mutableBytes];
    int16_t *audio = (int16_t *) [audioData bytes];    
    gsm_encode(encoder_st, audio, wire);
    
    return YES;
}
- (void)dealloc {
    gsm_destroy(encoder_st);
    gsm_destroy(decoder_st);
    encoder_st = nil;
    decoder_st = nil;
    [super dealloc];
}
@end
