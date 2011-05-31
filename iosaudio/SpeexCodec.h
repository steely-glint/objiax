//
//  SpeexCodec.h
//  objiax
//
//  Created by Tim Panton on 17/05/2011.
//  Copyright 2011 phonefromhere.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CodecProtocol.h"
#import "speex/speex.h"

@interface SpeexCodec : NSObject <CodecProtocol> {
    void * encoder_st;
    void * decoder_st;
	SpeexBits eBits;
	SpeexBits dBits;
}

@end
