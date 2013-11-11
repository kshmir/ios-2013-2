//
//  PBullet.m
//  Pombies
//
//  Created by Cristian Pereyra on 11/10/13.
//  Copyright (c) 2013 Cristian Pereyra. All rights reserved.
//

#import "PBullet.h"

@implementation PBullet {
    HelloWorldLayer * _layer;
}



+ (PBullet *) spriteWithFile: (NSString *) file andLayer: (HelloWorldLayer *) layer {
    PBullet * bullet = [self spriteWithFile:file];
    
    bullet->_layer = layer;
    
    return bullet;
}


- (void) deleteBullet {
    [_layer removeChild:self];
    [[_layer space] removeBody:self.chipmunkBody];
    [[_layer space] removeShape:self.chipmunkBody.data];
}

@end
