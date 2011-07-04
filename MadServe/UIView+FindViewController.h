//
//  UIView+FindViewController.h
//
//  Created by Oliver Drobnik on 9/24/10.
//  Copyright 2010 Drobnik.com. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface UIView (FindViewController)

- (UIViewController *) firstAvailableUIViewController;
- (id) traverseResponderChainForUIViewController;

@end

// this makes the -all_load linker flag unnecessary, -ObjC still needed
@interface DummyView : UIView

@end