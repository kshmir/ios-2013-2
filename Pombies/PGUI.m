//
//  PGUI.m
//  Pombies
//
//  Created by Cristian Pereyra on 11/21/13.
//  Copyright (c) 2013 Cristian Pereyra. All rights reserved.
//

#import "PGUI.h"

@implementation PGUI

+ (void) create: (HelloWorldLayer *) layer {
    CGSize winSize = [[CCDirector sharedDirector] winSize];
    PGUI * gui = [[PGUI alloc] init];
  
    CCLabelTTF * scoreText = [CCLabelTTF labelWithString:@"0" fontName:@"Verdana" fontSize:14.0];
    
    [scoreText setColor:ccc3(0,0,0)];
    [scoreText setPosition:ccp(winSize.width / 2, [scoreText contentSize].height)];
    
    CCSprite * live = [CCSprite spriteWithFile:@"live.png"];
    [live setScale: 0.5];
    CCLabelTTF * liveCount = [CCLabelTTF labelWithString:@"x 5" fontName:@"Verdana" fontSize:14.0];
    [liveCount setColor:ccc3(0,0,0)];
    
    [gui addChild: liveCount];
    [gui addChild: scoreText];
    
    [layer addChild: gui];
}

@end
