//
//  PGUI.h
//  Pombies
//
//  Created by Cristian Pereyra on 11/21/13.
//  Copyright (c) 2013 Cristian Pereyra. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HelloWorldLayer.h"
#import "cocos2d.h"

@interface PGUI : CCLayer
+ (PGUI *) create;


- (void) setScore: (int)score;
- (void) setLiveCount: (int)lives;
@end
