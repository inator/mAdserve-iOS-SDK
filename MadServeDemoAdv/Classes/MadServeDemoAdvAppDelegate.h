//
//  MadServeDemoAdvAppDelegate.h
//  MadServeDemoAdv
//
//  Created by Oliver Drobnik on 9/26/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class MadServeDemoAdvViewController;

@interface MadServeDemoAdvAppDelegate : NSObject <UIApplicationDelegate> {
    UIWindow *window;
    MadServeDemoAdvViewController *viewController;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet MadServeDemoAdvViewController *viewController;

@end

