//
//  HelloWorldLayer.m
//  Pombies
//
//  Created by Cristian Pereyra on 11/9/13.
//  Copyright Cristian Pereyra 2013. All rights reserved.
//
#import "HelloWorldLayer.h"
#import "AppDelegate.h"

@interface HelloWorldLayer()

@property (strong) CCTMXTiledMap *tileMap;
@property (strong) CCTMXLayer *background;

@end

@implementation HelloWorldLayer

// Helper class method that creates a Scene with the HelloWorldLayer as the only child.
+(CCScene *) scene
{
	// 'scene' is an autorelease object.
	CCScene *scene = [CCScene node];
    
	// 'layer' is an autorelease object.
	HelloWorldLayer *layer = [HelloWorldLayer node];
    
	// add layer as a child to scene
	[scene addChild: layer];
    
	// return the scene
	return scene;
}

-(id) init
{
	if( (self=[super init]) ) {
        self.tileMap = [CCTMXTiledMap tiledMapWithTMXFile:@"pv.tmx"];
        self.background = [self.tileMap layerNamed:@"Transparentes"];
        
        [self addChild:_tileMap z:-1];
    }
    return self;
}
@end
