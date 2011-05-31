//
//  objiax
//
//  Created by Tim Panton on 14/05/2011.
//  Copyright 2011 phonefromhere.com. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol AudioDataConsumer
- (void) consumeAudioData:(NSData*)data time:(NSInteger)stamp;
@end

