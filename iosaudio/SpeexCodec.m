//
//  SpeexCodec.m
//  objiax
//
//  Created by Tim Panton on 17/05/2011.
//  Copyright 2011 phonefromhere.com. All rights reserved.
//

#import "SpeexCodec.h"
#include <speex/speex_callbacks.h>


@implementation SpeexCodec
- (id) init{
    [super init];
    
    decoder_st = speex_decoder_init(&speex_nb_mode);
    
	
	encoder_st = speex_encoder_init(&speex_nb_mode);
	int tmp=1;
	speex_encoder_ctl(encoder_st, SPEEX_SET_VBR, &tmp);
	tmp=3;
	speex_encoder_ctl(encoder_st, SPEEX_SET_QUALITY, &tmp);
	tmp=2;
	speex_encoder_ctl(encoder_st, SPEEX_SET_COMPLEXITY, &tmp);
	tmp = 8000;
	speex_encoder_ctl(encoder_st,SPEEX_SET_SAMPLING_RATE,&tmp);
	speex_bits_init(&eBits);
	speex_bits_init(&dBits);
    
    
    return self;
}

- (NSString *) getName{
    return @"SPEEX";
}
- (NSInteger) getRate{
    return 8000;
}

- (BOOL) decode:(NSData *)wireData audioData:(NSMutableData *)audioData{
    [audioData setLength:320];
    uint8_t * wire = (uint8_t *) [wireData bytes];
    int16_t *audio = (int16_t *) [audioData mutableBytes];
    speex_bits_reset(&dBits);
    speex_bits_read_from(&dBits, (char *) wire,[wireData length]);
    speex_decode_int(decoder_st, &dBits, audio);
    return YES;
}


- (BOOL) encode:(NSData *)audioData wireData:(NSMutableData *)wireData{
    [wireData setLength:160];
    uint8_t * wire = (uint8_t *) [wireData mutableBytes];
    int16_t *audio = (int16_t *) [audioData bytes];    
    speex_bits_reset(&eBits);
    speex_encode_int(encoder_st, audio, &eBits);
    int nbBytes = speex_bits_write(&eBits, (char*) wire, 160);
    [wireData setLength:nbBytes];

    return YES;
}
- (void)dealloc {
    speex_encoder_destroy(encoder_st);
    speex_decoder_destroy(decoder_st);
    encoder_st = nil;
    decoder_st = nil;
    [super dealloc];
}
@end
