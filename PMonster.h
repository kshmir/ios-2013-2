//
//  PMonster.h
//  Pombies
//
//  Created by Cristian Pereyra on 11/10/13.
//  Copyright (c) 2013 Cristian Pereyra. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"
#import "ObjectiveChipmunk.h"
#import "HelloWorldLayer.h"

@interface PMonster : CCPhysicsSprite {
@private
	NSMutableArray *spOpenSteps;
	NSMutableArray *spClosedSteps;
    
}

@property (nonatomic, retain) NSMutableArray *spOpenSteps;
@property (nonatomic, retain) NSMutableArray *spClosedSteps;
@property (nonatomic, retain) NSMutableArray *shortestPath;
@property (nonatomic, retain) NSMutableArray *currentMovingPath;


- (id)initWithLayer:(HelloWorldLayer *)layer;
- (void)moveToward:(CGPoint)target;

@end
