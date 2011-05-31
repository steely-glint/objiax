//
//  CodecProtocol.h
//  objiax
//
//  Created by Tim Panton on 16/05/2011.
//  Copyright 2011 phonefromhere.com. All rights reserved.
//

#import <Foundation/Foundation.h>


@protocol CodecProtocol
- (NSString *) getName;
- (NSInteger) getRate;
- (BOOL) encode:(NSData *)audioData wireData:(NSMutableData *)wireData;
- (BOOL) decode:(NSData *)wireData audioData:(NSMutableData *)audioData;
@end
