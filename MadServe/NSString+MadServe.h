//
//  NSString+MadServe.h
//
//  Created by Oliver Drobnik on 9/24/10.
//  Copyright 2010 Drobnik.com. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NSString (MadServe)
- (NSString *)stringByUrlEncoding;
- (NSString * )md5;
@end


// this makes the -all_load linker flag unnecessary, -ObjC still needed
@interface DummyString : NSString

@end

