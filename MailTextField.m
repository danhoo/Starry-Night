//
//  MailTextField.m
//  Used in StarCluster, FluidDynamics, Zollner, TextSpline, Starry Night, others
//
//  Created by Dan Yu on 1/24/10.
//  Copyright 2010 Mind Console Productions. All rights reserved.
//

#import "MailTextField.h"


@implementation MCP_StarryNight_MailTextField

- (void)mouseDown:(NSEvent *)theEvent
{
	// Trigger a mail URL action.  This seems like
	// the "wrong" way to go about this (that is, I figured
	// there would be an IB Action for a regular NSTextField I could
	// use) but I couldn't find a more suitable way...
	NSURL *url;
		
	url = [NSURL URLWithString:@"mailto:dsyu@hotmail.com"
		   //		   "?subject=StarryNight Mac screensaver"
		   //		   "&body="
		   ];
	(void) [[NSWorkspace sharedWorkspace] openURL:url];	
}

-(void)resetCursorRects
{
	// override from NSView to display appropriate cursor when mouse is over our rect
    [self addCursorRect:[self visibleRect] cursor:[NSCursor pointingHandCursor]];	
}

@end
