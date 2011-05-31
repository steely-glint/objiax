//
//  GSM610Codec.h
//  objiax
//
//  Created by Tim Panton on 17/05/2011.
//  Copyright 2011 phonefromhere.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CodecProtocol.h"
#include "gsm.h"

@interface GSM610Codec : NSObject <CodecProtocol> {
    gsm encoder_st;
    gsm decoder_st;
}

@end
