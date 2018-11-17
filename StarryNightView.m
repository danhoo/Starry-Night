//
//  ScreensaverTemplateView.m
//  Starry Night
//
//  Created by Dan Yu on 1/2012.
//  Copyright (c) 2012, Mind Console Productions. Portions Copyright (c) 2010 Evan Green
//

#import "StarryNightView.h"

#define BUILDING_STYLE_COUNT 6
#define TILE_HEIGHT 8
#define TILE_WIDTH 8

typedef struct {
    unsigned long style;
    unsigned long height;
    unsigned long width;
    unsigned long beginX;
    unsigned long zCoordinate;
} MCP_StarryNight_BUILDING;

// Starry Night building styles. Buildings are made up of tiled 8x8 blocks.

unsigned char buildingTiles[BUILDING_STYLE_COUNT][TILE_HEIGHT][TILE_WIDTH] = {
    {
        {0, 0, 0, 0, 1, 0, 0, 1},
        {0, 0, 0, 0, 1, 0, 0, 1},
        {0, 0, 0, 0, 1, 0, 0, 1},
        {0, 0, 0, 0, 1, 0, 0, 1},
        {0, 0, 0, 0, 0, 0, 0, 0},
        {0, 0, 0, 0, 0, 0, 0, 0},
        {0, 0, 0, 0, 0, 0, 0, 0},
        {0, 0, 0, 0, 0, 0, 0, 0},
    },
    {
        {1, 1, 0, 0, 1, 1, 0, 0},
        {1, 1, 0, 0, 1, 1, 0, 0},
        {0, 0, 0, 0, 0, 0, 0, 0},
        {0, 0, 0, 0, 0, 0, 0, 0},
        {0, 0, 0, 0, 0, 0, 0, 0},
        {0, 0, 0, 0, 0, 0, 0, 0},
        {0, 0, 0, 0, 0, 0, 0, 0},
        {0, 0, 0, 0, 0, 0, 0, 0},
    },
    {
        {1, 0, 0, 0, 0, 0, 0, 0},
        {1, 0, 0, 0, 0, 0, 0, 0},
        {0, 0, 0, 0, 0, 0, 0, 0},
        {0, 0, 0, 0, 0, 0, 0, 0},
        {1, 0, 0, 0, 0, 0, 0, 0},
        {1, 0, 0, 0, 0, 0, 0, 0},
        {0, 0, 0, 0, 0, 0, 0, 0},
        {0, 0, 0, 0, 0, 0, 0, 0},
    },
    {
        {0, 1, 0, 1, 0, 1, 0, 0},
        {0, 0, 0, 0, 0, 0, 0, 0},
        {0, 0, 0, 0, 0, 0, 0, 0},
        {0, 0, 0, 0, 0, 0, 0, 0},
        {0, 0, 0, 0, 0, 0, 0, 0},
        {0, 0, 0, 0, 0, 0, 0, 0},
        {0, 0, 0, 0, 0, 0, 0, 0},
        {0, 0, 0, 0, 0, 0, 0, 0},
    },
    {
        {1, 0, 0, 0, 1, 0, 0, 0},
        {1, 0, 0, 0, 1, 0, 0, 0},
        {0, 0, 0, 0, 0, 0, 0, 0},
        {1, 0, 0, 0, 1, 0, 0, 0},
        {1, 0, 0, 0, 1, 0, 0, 0},
        {0, 0, 0, 0, 0, 0, 0, 0},
        {0, 0, 0, 0, 0, 0, 0, 0},
        {0, 0, 0, 0, 0, 0, 0, 0},
    },
    {
        {0, 1, 1, 0, 1, 1, 0, 0},
        {0, 1, 1, 0, 1, 1, 0, 0},
        {0, 0, 0, 0, 0, 0, 0, 0},
        {0, 0, 0, 0, 0, 0, 0, 0},
        {0, 0, 0, 0, 0, 0, 0, 0},
        {0, 0, 0, 0, 0, 0, 0, 0},
        {0, 0, 0, 0, 0, 0, 0, 0},
        {0, 0, 0, 0, 0, 0, 0, 0},
    },
};

#pragma mark MCP_StarryNight_View private definitions

@interface MCP_StarryNight_View()
- (void)deferredInitialization;
- (void)drawStars;
- (void)drawBuildings;
- (void)drawRain;
- (void)drawShootingStar;
- (void)drawFlasher;
- (int)getTopBuildingForScreenX:(int)screenX andScreenY:(int)screenY;
- (void)drawOneStarAtScreenX:(int)screenX andScreenY:(int)screenY;
- (void)refreshOverdrawnStarsFromLineAtScreenX1:(int)x1 andScreenY1:(int)y1 andScreenX2:(int)x2 andScreenY2:(int)y2;
@end

#pragma mark MCP_StarryNight_View implementation

@implementation MCP_StarryNight_View

// NOTE: We aren't using [[NSBundle mainBundle] bundleIdentifier] because this
// seems to be different when run via Preferences+preview vs actual screensaver mode
static NSString * const MyModuleName = @"com.mindconsoleproductions.screensaver.StarryNight";

- (id)initWithFrame:(NSRect)frame isPreview:(BOOL)isPreview
{
    self = [super initWithFrame:frame isPreview:isPreview];
    if (self) {
		
		// Initialize default prefs
		ScreenSaverDefaults *defaults = [ScreenSaverDefaults defaultsForModuleWithName:MyModuleName];
		[defaults registerDefaults:[NSDictionary dictionaryWithObjectsAndKeys:
									[[[NSBundle bundleForClass:[self class]] infoDictionary] objectForKey:@"CFBundleShortVersionString"], @"Version",
                                    [NSNumber numberWithInt:35], @"BuildingHeight", 
                                    [NSNumber numberWithInt:100], @"BuildingCount",
                                    @"YES", @"FlasherEnabled",
                                    @"NO", @"RetroColorEnabled",
                                    [NSNumber numberWithInt:5], @"BuildingWidthMin",
                                    [NSNumber numberWithInt:18], @"BuildingWidthMax",
                                    [NSNumber numberWithInt:10], @"StarDensity",
									nil]];
        
        // initialize some instance var values (consts, really)
        starsPerUpdate = 12;
        buildingPixelsPerUpdate = 15;
        minRainWidth = 2;
        maxRainWidth = 16;
        rainDropsPerUpdate = 15;
        flasherPeriodMs = 1500; //1700;
        maxShootingStarPeriodMs = 25000;
        maxShootingStarDurationMs = 1000;
        maxShootingStarSpeedX = 3.0;
        minShootingStarSpeedY = 0.1;
        maxShootingStarSpeedY = 1.0;
        maxShootingStarWidth = 4;        
                
		// Original windows code based all updates on 50 millisecond time intervals, so ensure
        // that our animateOneFrame framerate is to (approx) 50 milliseconds
        // Temp update for George Van Houten, 1/20.0 -> 1/10.0
        [self setAnimationTimeInterval:1/10.0];
        
        // Allocate our drawn cache now
        drawnStarPoints = [[NSMutableArray alloc] initWithCapacity:10000];
        drawnBuildingPoints = [[NSMutableArray alloc] initWithCapacity:10000];
        maxDrawnStarPoints = 10000; // we'll re-adjust these based on view size when view bounds get set
        maxDrawnBuildingPoints = 10000; 
        
        // Allocate our single workPath
        workPath = [[NSBezierPath bezierPath] retain]; // normally autoreleased
        
        // Defer the rest of the initialization, which requires an accurate view bounds which hasn't
        // been set yet
        instanceIsInitialized = NO;
        
        // Make view (and subviews) use a CA-based backing store (but not a CA-hosted backing store)
        // (basically dbl-buffer your view) Don't do this for this sort of saver -- the buffer will
        // redraw your view periodically and erase everything.
        //[self setWantsLayer:YES];
        
    }
    return self;
}

- (void)dealloc
{	
    [buildingArray release];
    [drawnStarPoints release];
    [drawnBuildingPoints release];
    [workPath release];
	[super dealloc];
}

- (void)startAnimation
{
    [super startAnimation];
    // Initialize state info here (for this saver we do all init in deferredInitialization)
}

- (void)stopAnimation
{
    [super stopAnimation];
}

- (void)drawRect:(NSRect)rect
{
    if (! instanceIsInitialized) {
        // TODO: Sanity check self.frame.width/height != 0?
        if (self.frame.size.width <= 0 || self.frame.size.height <= 0) {
            NSLog(@"DEBUG: Badness, getting to drawRect with 0 frame size?");
        }
        [self deferredInitialization];
    }
       
    [super drawRect:rect];
    // We're not using CALayer backed views, so drawRect will get called.
    // We can draw our view here, or in animateOneFrame (the latter getting
    // called at regular timer intervals, whereas drawRect only gets called
    // if we've marked the view as needing an update via [self setNeedsDisplay:YES])    
}

- (void)animateOneFrame
{
    // We should have a valid frame by this point, so do deferred init if necessary
    if (! instanceIsInitialized) {
        // TODO: Sanity check self.frame.width/height != 0?
        if (self.frame.size.width <= 0 || self.frame.size.height <= 0) {
            NSLog(@"DEBUG: Badness, getting to animateOneFrame with 0 frame size?");
        }
        [self deferredInitialization];
    }

    // Assume this gets called every 50 milliseconds, based on our setAnimationTimeInterval setting
    // It may be slightly off (since I believe this is done via a NSTimer)
    [self drawStars];
    [self drawBuildings];
//    [self drawRain];
    [self drawShootingStar];
    [self drawFlasher];
    
    return;
}

- (void)setFrameSize:(NSSize)newSize
{
    // Called when view's frame size changes -- adjust view and subviews as needed
    [super setFrameSize:newSize];
}

#pragma mark Configure sheet related methods

// Random note: If you're trying to find the actual userPrefs plist files for screensavers,
// look here: ~/Library/Preferences/ByHost/...

- (BOOL)hasConfigureSheet
{
    return YES;
}

- (NSWindow*)configureSheet
{
    ScreenSaverDefaults *defaults = [ScreenSaverDefaults defaultsForModuleWithName:MyModuleName];
	
    if (!configSheet) {
        if (![NSBundle loadNibNamed:@"ConfigureSheet" owner:self]) {
            NSLog(@"Failed to load configure sheet.");
        }
    }
    [configVersion setStringValue:[defaults stringForKey:@"Version"]];
    [configBuildingHeight setIntValue:[defaults integerForKey:@"BuildingHeight"]];
    [configBuildingCount setIntValue:[defaults integerForKey:@"BuildingCount"]];
    [configFlasher setState:[defaults boolForKey:@"FlasherEnabled"]];
    [configRetroColor setState:[defaults boolForKey:@"RetroColorEnabled"]];
    [configBuildingWidthMin setIntValue:[defaults integerForKey:@"BuildingWidthMin"]];
    [configBuildingWidthMax setIntValue:[defaults integerForKey:@"BuildingWidthMax"]];
    [configStarDensity setIntValue:[defaults integerForKey:@"StarDensity"]];

    return configSheet;
}

- (IBAction)configCancel:(id)sender
{
    [[NSApplication sharedApplication] endSheet:configSheet];
}

- (IBAction)configOk:(id)sender
{
    // update UserDefaults
    ScreenSaverDefaults *defaults = [ScreenSaverDefaults defaultsForModuleWithName:MyModuleName];
    [defaults setObject:[configVersion stringValue] forKey:@"Version"]; // unecessary...
    [defaults setInteger:[configBuildingHeight intValue] forKey:@"BuildingHeight"];
    [defaults setInteger:[configBuildingCount intValue] forKey:@"BuildingCount"];
    [defaults setBool:[configFlasher state] forKey:@"FlasherEnabled"];
    [defaults setBool:[configRetroColor state] forKey:@"RetroColorEnabled"];
    [defaults setInteger:[configBuildingWidthMin intValue] forKey:@"BuildingWidthMin"];
    [defaults setInteger:[configBuildingWidthMax intValue] forKey:@"BuildingWidthMax"];
    [defaults setInteger:[configStarDensity intValue] forKey:@"StarDensity"];

    // save defaults to disk
    [defaults synchronize];

    // Clear any existing preview
    instanceIsInitialized = NO;    
    [drawnStarPoints removeAllObjects];
    [drawnBuildingPoints removeAllObjects];
    [buildingArray release];
    [workPath removeAllPoints];
    
    [[NSApplication sharedApplication] endSheet:configSheet];
}


#pragma mark private method implementation

- (void)deferredInitialization {
    // Defer init until drawtime as we might not have an accurate view bounds until then

    ScreenSaverDefaults *defaults = [ScreenSaverDefaults defaultsForModuleWithName:MyModuleName];
    
    int buildingIndex;
    int flasherBuilding;
    int index2;
    int maxActualHeight;
    int maxHeight;
    int minX;
    int minXIndex;
    float randomHeight;
    int workBuildingCount;
    MCP_StarryNight_BUILDING swap;
    int minBuildingWidth, maxBuildingWidth;
    
    srand(time(NULL));
   
    // Clear main view (in case we got here due to configOk)
    [[NSColor blackColor] set];
    NSRect blackRect = NSMakeRect(0, 0, self.frame.size.width, self.frame.size.height);
    NSRectFill(blackRect);

    float buildingHeightPercentage = [defaults floatForKey:@"BuildingHeight"] / 100.0;
    
    // Determine the maximum height of a building
    maxHeight = (self.frame.size.height * buildingHeightPercentage) / TILE_HEIGHT;
    
    minBuildingWidth = [defaults integerForKey:@"BuildingWidthMin"];
    maxBuildingWidth = [defaults integerForKey:@"BuildingWidthMax"];    
    // Sanity check
    if (minBuildingWidth <= 0) {
        minBuildingWidth = 1;
    }
    if (maxBuildingWidth < minBuildingWidth) {
        maxBuildingWidth = minBuildingWidth + 1;
    }
    
    // Allocate and initialize the buildings
    flasherBuilding = 0;
    workBuildingCount = [defaults integerForKey:@"BuildingCount"];
    NSMutableData *workBuildingArray = [[NSMutableData alloc] initWithLength:sizeof(MCP_StarryNight_BUILDING) * workBuildingCount];
    maxActualHeight = 0;
    MCP_StarryNight_BUILDING* array = [workBuildingArray mutableBytes];
    for (buildingIndex = 0; buildingIndex < workBuildingCount; buildingIndex++) {
        array[buildingIndex].style = rand() % BUILDING_STYLE_COUNT;
        // Squaring the random height makes for a more interesting distribution
        // of buildings.
        randomHeight = (float)rand() / (float)RAND_MAX;
        array[buildingIndex].height = randomHeight * randomHeight * (float)maxHeight;
        array[buildingIndex].height += 1; // ???
        array[buildingIndex].width = minBuildingWidth + (rand() % (maxBuildingWidth - minBuildingWidth));
        array[buildingIndex].beginX = rand() % (int)(self.frame.size.width);
        array[buildingIndex].zCoordinate = buildingIndex + 1; // ???
        if (array[buildingIndex].height > maxActualHeight) {
            maxActualHeight = array[buildingIndex].height;
            flasherBuilding = buildingIndex;
        }
    }
    
    // Determine the flasher coordinates. The flasher goes at the center of the
    // top of the tallest building.
    flasherX = array[flasherBuilding].beginX + (array[flasherBuilding].width * TILE_WIDTH / 2);
    flasherY = self.frame.size.height - (array[flasherBuilding].height * TILE_HEIGHT);    
    
    // Sort the buildings by X coordinate.
    for (buildingIndex = 0; buildingIndex < workBuildingCount - 1; buildingIndex++) {
        // Find the building with the lowest X coordinate.
        minX = self.frame.size.width;
        minXIndex = -1;
        for (index2 = buildingIndex; index2 < workBuildingCount; index2 += 1) {
            if (array[index2].beginX < minX) {
                minX = array[index2].beginX;
                minXIndex = index2;
            }
        }
        // Swap it into position.
        if (buildingIndex != minXIndex) {
            swap = array[buildingIndex]; // TODO: Verify this field-wise assignment actually works
            array[buildingIndex] = array[minXIndex];
            array[minXIndex] = swap;
        }        
    }
    
    // Init some run-time instance vars
    flasherOn = NO;
    flasherTime = 0;
    shootingStarActive = NO;
    shootingStarTime = 0;
    shootingStarStartX = 0;
    shootingStarStartY = 0;
    shootingStarVelocityX = 0.0;
    shootingStarVelocityY = 0.0;
    shootingStarDuration = 0;    
    
    buildingArray = workBuildingArray; 
    
    // Set max cache pts based on overall view size -- e.g. keep overall density of
    // stars for a M x N view to be (M x N x percentage).  This probably needs tweaking.
    float starDensityPercentage = (float)[defaults integerForKey:@"StarDensity"] / 100.0;
    maxDrawnStarPoints = (self.frame.size.width * self.frame.size.height) * starDensityPercentage;
    maxDrawnBuildingPoints = (self.frame.size.width * self.frame.size.height) * 0.20;    
    // sanity check
    if (maxDrawnStarPoints <= 0) {
        maxDrawnStarPoints = starsPerUpdate;
    }
    if (maxDrawnBuildingPoints <= 0) {
        maxDrawnBuildingPoints = buildingPixelsPerUpdate;
    }
    
    instanceIsInitialized = YES;
}


- (void)drawStars {
    float randomY;
    int starIndex;
    int starX;
    int starY;
    NSPoint starPoint;
    NSRect starRect;
    
    // Randomly sprinkle a certain number of stars on the screen.

    starIndex = 0;
    while (starIndex < starsPerUpdate) {
        starX = rand() % (int)self.frame.size.width;
        
        // Squaring the Y coordinate puts more stars at the top and gives it
        // a more realistic (and less static-ish) view.
        
        randomY = (float)rand() / (float)RAND_MAX;
        starY = (int)(randomY * randomY * (float)self.frame.size.height);
        if ([self getTopBuildingForScreenX:starX andScreenY:starY] != -1) {
            continue;
        }

        [self drawOneStarAtScreenX:starX andScreenY:starY];
        
        // TO CONSIDER: it's probably faster to collect all stars for this update
        // in a NSRect array and call NSRectFillList instead

        // Cache point in our drawnStars array to later "erase"
        starPoint.x = starX;
        starPoint.y = starY;
        [drawnStarPoints addObject:[NSValue valueWithPoint:starPoint]];
        
        starIndex += 1;
    }

    // If necessary, erase some previously drawn stars
    if ([drawnStarPoints count] > maxDrawnStarPoints) {
        starIndex = 0;
        while (starIndex < starsPerUpdate) {
            // sanity check
            if ([drawnStarPoints count] <= 0) {
                break;
            }
            // "erase" a previous drawn pt by drawing a black pt at the same location
            [[NSColor blackColor] set];
            starPoint = [[drawnStarPoints objectAtIndex:starIndex] pointValue];
            starRect = NSMakeRect(starPoint.x, starPoint.y, 1.0, 1.0);
            NSRectFill(starRect);
            [drawnStarPoints removeObjectAtIndex:starIndex];
            starIndex++;
        }
    }
    
}


- (void)drawBuildings {
    int building;
    int buildingHeightRange;
    int buildingHeightOffset;
    int pixelsOn;
    int potentialX;
    int potentialY;
    int style;
    int tileX;
    int tileY;
    NSColor *buildingColor;
    NSRect buildingRect;
    NSPoint buildingPoint;
    int drawnBuildingPtIndex;

    ScreenSaverDefaults *defaults = [ScreenSaverDefaults defaultsForModuleWithName:MyModuleName];
    const MCP_StarryNight_BUILDING* array = [buildingArray bytes];
    
    buildingHeightRange = self.frame.size.height - flasherY;
    buildingHeightOffset = flasherY;
    pixelsOn = 0;
    while (pixelsOn < buildingPixelsPerUpdate) {
        potentialX = rand() % (int)self.frame.size.width;
        potentialY = buildingHeightOffset + (rand() % buildingHeightRange);
        building = [self getTopBuildingForScreenX:potentialX andScreenY:potentialY];
        if (building == -1) {
            continue;
        }
        
        tileX = (potentialX - array[building].beginX) % TILE_WIDTH;
        tileY = potentialY % TILE_HEIGHT;
        style = array[building].style;
        if (buildingTiles[style][tileY][tileX] == 0) {
            continue;
        }

        buildingColor = [NSColor colorWithCalibratedRed:(248.0 / 255.0)
                                          green:(241.0 / 255.0)
                                           blue:(3.0 / 255.0)
                                          alpha:1.0];
        if ([defaults boolForKey:@"RetroColorEnabled"]) {
            buildingColor = [buildingColor colorUsingColorSpace:[NSColorSpace genericGrayColorSpace]];
        }
        [buildingColor set];
        buildingRect = NSMakeRect((float)potentialX, (float)potentialY, 1.0, 1.0);
        NSRectFill(buildingRect);
        
        // Cache point in our drawnBuilding array to later "erase"
        buildingPoint.x = potentialX;
        buildingPoint.y = potentialY;
        [drawnBuildingPoints addObject:[NSValue valueWithPoint:buildingPoint]];
        
        pixelsOn += 1;
    }

    // If necessary, erase some previously drawn building pts
    if ([drawnBuildingPoints count] > maxDrawnBuildingPoints) {
        drawnBuildingPtIndex = 0;
        while (drawnBuildingPtIndex < buildingPixelsPerUpdate) {
            // "erase" a previous drawn pt by drawing a black pt at the same location
            [[NSColor blackColor] set];
            buildingPoint = [[drawnBuildingPoints objectAtIndex:drawnBuildingPtIndex] pointValue];
            buildingRect = NSMakeRect(buildingPoint.x, buildingPoint.y, 1.0, 1.0);
            NSRectFill(buildingRect);
            [drawnBuildingPoints removeObjectAtIndex:drawnBuildingPtIndex];
            drawnBuildingPtIndex++;
        }
    }    
    
    return;
}


- (void)drawRain {
    int dropIndex;
    int lineWidth;
    int rainX;
    int rainY;
    float prevLineWidth = [workPath lineWidth];
    
    [[NSColor blackColor] set];    
    
    for (dropIndex = 0; dropIndex < rainDropsPerUpdate; dropIndex += 1) {
        lineWidth = minRainWidth + (rand() % (maxRainWidth - minRainWidth));
        
        rainX = rand() % (int)self.frame.size.width;
        rainY = rand() % (int)self.frame.size.height;
        
        [workPath setLineWidth:lineWidth];
        [workPath removeAllPoints];
        [workPath moveToPoint:NSMakePoint(rainX, rainY)];
        [workPath lineToPoint:NSMakePoint(rainX + 1, rainY + 1)];
        [workPath stroke];        
        [workPath setLineWidth:prevLineWidth];
    }
}

- (void)drawShootingStar {
    int currentX;
    int currentY;
    int lineWidth;
    int maxStarY;
    int newX;
    int newY;
    float randomY;
    NSColor *shootingStarColor;
    NSLineCapStyle prevLineCapStyle;
    NSLineJoinStyle prevLineJoinStyle;
    float prevLineWidth;
    
    ScreenSaverDefaults *defaults = [ScreenSaverDefaults defaultsForModuleWithName:MyModuleName];
    float buildingHeightPercentage = [defaults floatForKey:@"BuildingHeight"] / 100.0;
    
    maxStarY = self.frame.size.height - (self.frame.size.height * buildingHeightPercentage / TILE_HEIGHT);

    // If there is no shooting star now, count time until the decided period
    // has ended.
    
    if (! shootingStarActive) {
        
        // If this causes the shooting star time to fire, set up the shooting
        // star.
        
        if (shootingStarTime <= 50) {
            shootingStarTime = 0;
            shootingStarActive = YES;
            
            // The shooting star should start somewhere between the top of the
            // buildings and the top of the screen.
            
            shootingStarStartX = rand() % (int)self.frame.size.width;
            randomY = (float)rand() / (float)RAND_MAX;
            shootingStarStartY = (int)(randomY * randomY * (float)maxStarY);
            shootingStarDuration = (rand() % maxShootingStarDurationMs) + 1;
            shootingStarVelocityX = (((float)rand() / (float)RAND_MAX) *
                                       (2.0 * maxShootingStarSpeedX)) - maxShootingStarSpeedX; // min?
            
            shootingStarVelocityY = (((float)rand() / (float)RAND_MAX) *
                                       (maxShootingStarSpeedY - minShootingStarSpeedY)) + minShootingStarSpeedY;
            
            // No shooting star now, keep counting down.
            
        } else {
            shootingStarTime -= 50;
            return;
        }
    }

    prevLineCapStyle = [workPath lineCapStyle];
    prevLineJoinStyle = [workPath lineJoinStyle];
    prevLineWidth = [workPath lineWidth];
    [workPath setLineCapStyle:NSRoundLineCapStyle];
    [workPath setLineJoinStyle:NSRoundLineJoinStyle];
    lineWidth = (int)(shootingStarTime * maxShootingStarWidth / shootingStarDuration);
    [workPath setLineWidth:lineWidth];
    
    shootingStarColor = [NSColor colorWithCalibratedRed:100.0 / 255.0 green:0.0 blue:0.0 alpha:1.0];
    if ([defaults boolForKey:@"RetroColorEnabled"]) {
        shootingStarColor = [shootingStarColor colorUsingColorSpace:[NSColorSpace genericGrayColorSpace]];
    }
    
    // Draw the shooting star line from the current location to the next
    // location.
    
    currentX = shootingStarStartX + ((float)shootingStarTime * shootingStarVelocityX);
    currentY = shootingStarStartY + ((float)shootingStarTime * shootingStarVelocityY);
    
    if (shootingStarTime < shootingStarDuration) {
        newX = currentX + (50.0 * shootingStarVelocityX);
        newY = currentY + (50.0 * shootingStarVelocityY);
        
        // If the shooting star is about to fall behind a building, cut it off
        // now. Otherwise, draw it.
        
        if ([self getTopBuildingForScreenX:newX andScreenY:newY] != -1) {
            shootingStarTime = shootingStarDuration;
            
        } else {

            [shootingStarColor set];
            
            [workPath removeAllPoints];
            [workPath moveToPoint:NSMakePoint(currentX, currentY)];
            [workPath lineToPoint:NSMakePoint(newX, newY)];
            [workPath stroke];              
        }
    }
    
    // Draw background from the start to the current value.
    
    shootingStarColor = [NSColor blackColor];

    [shootingStarColor set];
    
    lineWidth = maxShootingStarWidth + 1; // +2?
    [workPath setLineWidth:lineWidth];    
    
    [workPath removeAllPoints];
    [workPath moveToPoint:NSMakePoint(shootingStarStartX, shootingStarStartY)];
    [workPath lineToPoint:NSMakePoint(currentX, currentY)];
    [workPath stroke];        
    
    [workPath setLineCapStyle:prevLineCapStyle];
    [workPath setLineJoinStyle:prevLineJoinStyle];        
    [workPath setLineWidth:prevLineWidth];
        
    // Update the counters. If there is more time on the shooting star, just
    // update time.
    
    if (shootingStarTime < shootingStarDuration) {
        shootingStarTime += 50;
    
        // The shooting star is sadly over. Reset the counters and patiently wait
        // for the next one.        
    } else {
        // If there are any stars we might have drawn over, redraw them now
        [self refreshOverdrawnStarsFromLineAtScreenX1:shootingStarStartX andScreenY1:shootingStarStartY andScreenX2:currentX andScreenY2:currentY];
        shootingStarActive = NO;
        shootingStarTime = rand() % maxShootingStarPeriodMs;
    }
    
}


- (void)drawFlasher {
    BOOL blackOutFlasher;
    NSColor *flasherColor;
    NSLineCapStyle prevLineCapStyle;
    NSLineJoinStyle prevLineJoinStyle;
    float prevLineWidth;
    
    ScreenSaverDefaults *defaults = [ScreenSaverDefaults defaultsForModuleWithName:MyModuleName];    
    
    blackOutFlasher = NO;
    
    if (! [defaults boolForKey:@"FlasherEnabled"]) {
        flasherOn = NO;
        return;
    }
    
    flasherTime += 50; // assume approx 50 ms have elapsed with each animateOneFrame call
    if (flasherTime >= flasherPeriodMs) {
        flasherTime -= flasherPeriodMs; 
        if (! flasherOn) {
            flasherOn = YES;
        } else {
            flasherOn = NO;
            blackOutFlasher = YES;
        }
    }
    
    // TODO: This is redundant -- once we've drawn the flasher (or "erased" it), we don't
    // need to draw anything until the next flasherPeriodMs
    if (flasherOn || blackOutFlasher) {
        
        if (flasherOn) {
            flasherColor = [NSColor colorWithCalibratedRed:190.0 / 255.0 green:0.0 blue:0.0 alpha:1.0];
            if ([defaults boolForKey:@"RetroColorEnabled"]) {
                flasherColor = [flasherColor colorUsingColorSpace:[NSColorSpace genericGrayColorSpace]];
            }
        } else {
            flasherColor = [NSColor blackColor];        
        }
        [flasherColor set];
        
        prevLineCapStyle = [workPath lineCapStyle];
        prevLineJoinStyle = [workPath lineJoinStyle];
        prevLineWidth = [workPath lineWidth];
        [workPath setLineCapStyle:NSRoundLineCapStyle];
        [workPath setLineJoinStyle:NSRoundLineJoinStyle];
        if (blackOutFlasher) {
            // For some odd reason, black line leaves behind a little bit of an outline so make it wider to get rid of this
            [workPath setLineWidth:7.0];
        } else {
            [workPath setLineWidth:5.0];
        }
        
        [workPath removeAllPoints];
        [workPath moveToPoint:NSMakePoint(flasherX, flasherY)];
        [workPath lineToPoint:NSMakePoint(flasherX + 1, flasherY + 1)];
        [workPath stroke];        

        [workPath setLineCapStyle:prevLineCapStyle];
        [workPath setLineJoinStyle:prevLineJoinStyle];        
        [workPath setLineWidth:prevLineWidth];
    }
}


- (int)getTopBuildingForScreenX:(int)screenX andScreenY:(int)screenY {
    
    int building;
    int buildingRight;
    int buildingTop;
    int frontBuilding;
    int maxZ;
    
    ScreenSaverDefaults *defaults = [ScreenSaverDefaults defaultsForModuleWithName:MyModuleName];
    const MCP_StarryNight_BUILDING* array = [buildingArray bytes];
    
    frontBuilding = -1;
    maxZ = 0;
    for (building = 0; building < [defaults integerForKey:@"BuildingCount"]; building += 1) {
        
        // The buildings are sorted by X coordinate. If this building starts
        // to the right of the pixel in question, none of the rest intersect.
        
        if (array[building].beginX > screenX) {
            break;
        }
        
        // Check to see if the pixel is inside this building.
        
        buildingTop = self.frame.size.height - (array[building].height * TILE_HEIGHT);
        buildingRight = array[building].beginX + (array[building].width * TILE_WIDTH);
        
        if ((screenX >= array[building].beginX) &&
            (screenX < buildingRight) &&
            (screenY > buildingTop)) {
            
            // If this is the front-most building, mark it as the new winner.
            
            if (array[building].zCoordinate > maxZ) {
                frontBuilding = building;
                maxZ = array[building].zCoordinate;
            }
        }
    }
    
    return frontBuilding;
}

- (void)drawOneStarAtScreenX:(int)screenX andScreenY:(int)screenY {
    NSColor *starColor;
    NSRect starRect;
    
    ScreenSaverDefaults *defaults = [ScreenSaverDefaults defaultsForModuleWithName:MyModuleName];
    
    // Set the current draw color
    starColor = [NSColor colorWithCalibratedRed:((float)(rand() % 180) / 255.0) 
                                          green:((float)(rand() % 180) / 255.0) 
                                           blue:((float)(rand() % 255) / 255.0)  alpha:1.0];
    if ([defaults boolForKey:@"RetroColorEnabled"]) {
        starColor = [starColor colorUsingColorSpace:[NSColorSpace genericGrayColorSpace]];
    }
    [starColor set];
        
    // Draw a point using a tiny NSRect (yes, this is the way to do it in Cocoa)
    starRect = NSMakeRect((float)screenX, (float)screenY, 1.0, 1.0);
    NSRectFill(starRect);
}

- (void)refreshOverdrawnStarsFromLineAtScreenX1:(int)x1 andScreenY1:(int)y1 andScreenX2:(int)x2 andScreenY2:(int)y2 {

#if 0    
    NSRect starRect;
    [[NSColor greenColor] set];
    // Draw a point using a tiny NSRect (yes, this is the way to do it in Cocoa)
    starRect = NSMakeRect(10.0, 10.0, 50, 50);
    NSRectFill(starRect);  
    // (this draws in upper left corner in our flipped view, btw)
#endif
    
    // If there are any stars we might have drawn over, redraw them now
    // TODO: This isn't quite right. Also, it's probably unnecessarily expensive
    int redrawLoop;
    NSPoint starPoint;
    float slope;
    
    // Calculate line eqn
    if (x1 == x2) {
        // Vertical line
        for (redrawLoop = 0; redrawLoop < [drawnStarPoints count]; redrawLoop++) {
            starPoint = [[drawnStarPoints objectAtIndex:redrawLoop] pointValue];
            if (starPoint.x == x1) {
                [self drawOneStarAtScreenX:starPoint.x andScreenY:starPoint.y];
            }
        }        
    } else if (y1 == y2) {
        // Horizontal line
        for (redrawLoop = 0; redrawLoop < [drawnStarPoints count]; redrawLoop++) {
            starPoint = [[drawnStarPoints objectAtIndex:redrawLoop] pointValue];
            if (starPoint.y == y1) {
                [self drawOneStarAtScreenX:starPoint.x andScreenY:starPoint.y];
            }
        }
    } else {
        // Get line eqn from two pts and slope
        slope = (float)(y1 - y2) / (float)(x1 - x2);
        // line: y = nX + b
        // y - y1 = slope * (x - x1)
        // y = (slope * x) - (slope * x1) + y1
        float b = (-1) * (slope * x1) + y1;
        // pt: (p, q)
        // distance from pt to line is:
        //  abs( (n * p) + (-1) * q + b ) / sqrt( n^2 + 1 )
        // http://www.worsleyschool.net/science/files/linepoint/method5.html
        // http://www.mathsisfun.com/algebra/line-equation-2points.html
        float ptDist = 0;
#define PTDIST_THRESHOLD 5.0        
        for (redrawLoop = 0; redrawLoop < [drawnStarPoints count]; redrawLoop++) {
            starPoint = [[drawnStarPoints objectAtIndex:redrawLoop] pointValue];
            ptDist = fabs( (slope * starPoint.x) + (-1.0 * starPoint.y) + b ) / (slope * slope + 1);
            if (ptDist <= PTDIST_THRESHOLD) {
                [self drawOneStarAtScreenX:starPoint.x andScreenY:starPoint.y];
            }
        }
    }
}


#pragma mark NSView overrides

- (BOOL)isFlipped {
    // Flip drawing coordinates
    return YES;
}

@end
