//
//  UIView+FindViewController.m
//
//  Created by Oliver Drobnik on 9/24/10.
//  Copyright 2010 Drobnik.com. All rights reserved.
//

#import "UIView+FindViewController.h"


@implementation UIView (FindViewController)


- (UIViewController *) firstAvailableUIViewController 
{
    // convenience function for casting and to "mask" the recursive function
    return (UIViewController *)[self traverseResponderChainForUIViewController];
}

- (id) traverseResponderChainForUIViewController 
{
    id nextResponder = [self nextResponder];
    if ([nextResponder isKindOfClass:[UIViewController class]]) {
        return nextResponder;
    } else if ([nextResponder isKindOfClass:[UIView class]]) {
        return [nextResponder traverseResponderChainForUIViewController];
    } else {
        return nil;
    }
}

@end

@implementation DummyView

@end