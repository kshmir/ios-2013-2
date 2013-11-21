//
//  PGUI.m
//  Pombies
//
//  Created by Cristian Pereyra on 11/21/13.
//  Copyright (c) 2013 Cristian Pereyra. All rights reserved.
//

#import "PGUI.h"

@implementation PGUI {
    CCLabelTTF * scoreText;
    CCLabelTTF * liveCount;
}

- (void) setScore: (int)score {
    [self->scoreText setString:[NSString stringWithFormat:@"Score: %d", score]];
}

- (void) setLiveCount: (int)lives {
    [self->liveCount setString:[NSString stringWithFormat:@"Lives: %d", lives]];
}

+ (PGUI *) create {
    CGSize winSize = [[CCDirector sharedDirector] winSize];
    PGUI * gui = [[PGUI alloc] init];
  
    CCLabelTTF * scoreText = [CCLabelTTF labelWithString:@"Score: 0" fontName:@"Verdana" fontSize:14.0];
    [scoreText setColor:ccc3(0,0,0)];
    [scoreText setPosition:ccp(winSize.width / 2, [scoreText contentSize].height)];
    
    CCLabelTTF * liveCount = [CCLabelTTF labelWithString:@"Lives: 10" fontName:@"Verdana" fontSize:14.0];
    [liveCount setColor:ccc3(0,0,0)];
    [liveCount setPosition:ccp(winSize.width / 2,
                               winSize.height - [liveCount contentSize].height * 2)];

    
    gui->scoreText = scoreText;
    gui->liveCount = liveCount;
    
    [gui addChild: liveCount];
    [gui addChild: scoreText];
    
    return gui;
}

@end
