//
//  PBullet.h
//  Pombies
//
//  Created by Cristian Pereyra on 11/10/13.
//  Copyright (c) 2013 Cristian Pereyra. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"
#import "HelloWorldLayer.h"

@interface PBullet : CCPhysicsSprite
+ (PBullet *) spriteWithFile: (NSString *) file andLayer: (HelloWorldLayer *) layer;
- (void) deleteBullet;
@end
