//
//  ShootingStarView.m
//  Starry Night
//
//  Created by Dan Yu on 1/7/12.
//  Copyright 2012 __MyCompanyName__. All rights reserved.
//

#import "ShootingStarView.h"


@implementation MCP_ShootingStarView

@synthesize drawShootingStarForeground, foregroundColor, foregroundLineWidth, foregroundX1, foregroundY1, foregroundX2, foregroundY2;
@synthesize drawShootingStarBackground, backgroundLineWidth, backgroundX1, backgroundY1, backgroundX2, backgroundY2;


- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
        workPath = [[NSBezierPath bezierPath] retain]; // normally autoreleased
        [workPath setLineCapStyle:NSRoundLineCapStyle];
        [workPath setLineJoinStyle:NSRoundLineJoinStyle];
    }
    return self;
}

- (void)dealloc
{	
    [workPath release];
	[super dealloc];
}

//- (BOOL)isOpaque
//{
//    return YES;
//}

- (void)drawRect:(NSRect)dirtyRect {
    
    // Transparent background
//    [[NSColor clearColor] set];
//    NSRectFill(dirtyRect);
    [[NSColor clearColor] set];
    NSRectFillUsingOperation(dirtyRect, NSCompositeCopy);
        
    // Draw foreground
    if (drawShootingStarForeground) {
        [foregroundColor set];
        [workPath setLineWidth:foregroundLineWidth];    
        [workPath removeAllPoints];
        [workPath moveToPoint:NSMakePoint(foregroundX1, foregroundY1)];
        [workPath lineToPoint:NSMakePoint(foregroundX2, foregroundY2)];
        [workPath stroke];              
    }
    
    // Draw background
    if (drawShootingStarBackground) {
        [[NSColor blackColor] set]; // clearColor
        [workPath setLineWidth:backgroundLineWidth];    
        [workPath removeAllPoints];
        [workPath moveToPoint:NSMakePoint(backgroundX1, backgroundY1)];
        [workPath lineToPoint:NSMakePoint(backgroundX2, backgroundY2)];
        [workPath stroke];                  
    }
}

#pragma mark NSView overrides

- (BOOL)isFlipped {
    // Flip drawing coordinates
    return YES;
}

@end
