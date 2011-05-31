//
//  G722Codec.h
//  objiax
//
//  Created by Tim Panton on 17/05/2011.
//  Copyright 2011 phonefromhere.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CodecProtocol.h"
#import "g722.h"

@interface G722Codec : NSObject <CodecProtocol>{
    g722_encode_state_t encoder_st;
    g722_decode_state_t decoder_st;
}

@end
