//
//  UlawCodec.m
//  objiax
//
//  Created by Tim Panton on 16/05/2011.
//  Copyright 2011 phonefromhere.com. All rights reserved.
//

#import "UlawCodec.h"
#import "ulaw.h"


@implementation UlawCodec
- (NSString *) getName{
    return @"ULAW";
}
- (NSInteger) getRate{
    return 8000;
}

- (BOOL) decode:(NSData *)wireData audioData:(NSMutableData *)audioData{
    int len = [wireData length];

    int count=0;
    [audioData setLength:(len*2)];
    uint8_t * wire = (uint8_t *) [wireData bytes];
    int16_t *audio = (int16_t *) [audioData mutableBytes];
    for (count =0; count <len ; count++){
        audio[count] =  ulaw_decode [(int)wire[count]];

    }
    return YES;
}


- (BOOL) encode:(NSData *)audioData wireData:(NSMutableData *)wireData{
    int len = [audioData length]/2;
    int count = len;
    [wireData setLength:len];
    uint8_t * wire = (uint8_t *) [wireData mutableBytes];
    int16_t *audio = (int16_t *) [audioData bytes];    
    while (--count >= 0)
    {	
        if (audio[count] >= 0)
            wire[count] = ulaw_encode [audio[count] / 4] ;
        else
            wire[count] = 0x7F & ulaw_encode [audio[count] / -4] ;
    } 
    
    return YES;
}
@end
