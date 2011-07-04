//
//  NSURL+MadServe.h
//
//  Created by Oliver Drobnik on 9/25/10.
//  Copyright 2010 Drobnik.com. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NSURL (MadServe)

- (BOOL)isDeviceSupported;

@end

// this makes the -all_load linker flag unnecessary, -ObjC still needed
@interface DummyURL

@end