//
//  NSURL+MadServe.m
//
//  Created by Oliver Drobnik on 9/25/10.
//  Copyright 2010 Drobnik.com. All rights reserved.
//

#import "NSURL+MadServe.h"


@implementation NSURL (MadServe)

- (BOOL)isDeviceSupported
{
	NSString *scheme = [self scheme];
	NSString *host = [self host];
	
	if ([scheme isEqualToString:@"tel"] || [scheme isEqualToString:@"sms"] || [scheme isEqualToString:@"mailto"])
	{
		return YES;
	}
	
	if ([scheme isEqualToString:@"http"])
	{
		if ([host isEqualToString:@"maps.google.com"])
		{
			return YES;
		}
		
		if ([host isEqualToString:@"www.youtube.com"])
		{
			return YES;
		}
		
		if ([host isEqualToString:@"phobos.apple.com"])
		{
			return YES;
		}
		
		if ([host isEqualToString:@"itunes.apple.com"])
		{
			return YES;
		}
	}
	
	return NO;	
}

@end


@implementation DummyURL

@end
