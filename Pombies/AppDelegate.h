//
//  AppDelegate.h
//  Pombies
//
//  Created by Cristian Pereyra on 11/9/13.
//  Copyright Cristian Pereyra 2013. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "cocos2d.h"
#import "chipmunk.h"

// Added only for iOS 6 support
@interface MyNavigationController : UINavigationController <CCDirectorDelegate>
@end

@interface AppController : NSObject <UIApplicationDelegate>
{
	UIWindow *window_;
	MyNavigationController *navController_;

	CCDirectorIOS	*__unsafe_unretained director_;							// weak ref
}

@property (nonatomic, strong) UIWindow *window;
@property (readonly) MyNavigationController *navController;
@property (unsafe_unretained, readonly) CCDirectorIOS *director;

@end
