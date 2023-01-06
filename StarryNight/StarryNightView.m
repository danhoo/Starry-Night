//
//  StarryNightView.m
//  StarryNight
//
//  Created by dsyu on 12/12/22.
//

#import "StarryNightView.h"

#define BUILDING_STYLE_COUNT 6
#define TILE_HEIGHT 8
#define TILE_WIDTH 8

#define MIN_BITMAP_WIDTH 768.0 // 512 is too small, 1024 a little too big

#define DEFAULT_BUILDING_HEIGHT 35
#define DEFAULT_BUILDING_COUNT 30
#define DEFAULT_BUILDING_MIN_WIDTH 5
#define DEFAULT_BUILDING_MAX_WIDTH 18
#define DEFAULT_STAR_DENSITY 10
#define DEFAULT_REFRESH_TIME 15 // in minutes, NSTimer in seconds

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

@interface StarryNightView()
- (void)deferredInitialization;
- (void)drawStars;
- (void)drawBuildings;
- (void)drawShootingStar;
- (void)drawFlasher;
- (int)getTopBuildingForScreenX:(int)screenX andScreenY:(int)screenY;
- (void)drawOneStarAtScreenX:(int)screenX andScreenY:(int)screenY;
- (void)refreshOverdrawnStarsFromLineAtScreenX1:(int)x1 andScreenY1:(int)y1 andScreenX2:(int)x2 andScreenY2:(int)y2;
@end

@implementation StarryNightView

// NOTE: We aren't using [[NSBundle mainBundle] bundleIdentifier] because this
// seems to be different when run via Preferences+preview vs actual screensaver mode
//static NSString * const MyModuleName = @"mindconsoleproductions.StarryNight";
static NSString * const MyModuleName = @"com.mindconsoleproductions.screensaver.StarryNight";

- (instancetype)initWithFrame:(NSRect)frame isPreview:(BOOL)isPreview
{
    self = [super initWithFrame:frame isPreview:isPreview];
    if (self) {
        
        //srand((unsigned int)time(NULL));
        srandomdev();
        
        // Initialize default prefs
        ScreenSaverDefaults *defaults = [ScreenSaverDefaults defaultsForModuleWithName:MyModuleName];
        [defaults registerDefaults:[NSDictionary dictionaryWithObjectsAndKeys:
                                    [NSString stringWithCString:"1.01" encoding:NSUTF8StringEncoding], @"Version",
                                    [NSNumber numberWithInt:DEFAULT_BUILDING_HEIGHT], @"BuildingHeight",
                                    [NSNumber numberWithInt:DEFAULT_BUILDING_COUNT], @"BuildingCount",
                                    @"YES", @"FlasherEnabled",
                                    @"NO", @"RetroColorEnabled",
                                    [NSNumber numberWithInt:DEFAULT_BUILDING_MIN_WIDTH], @"BuildingWidthMin",
                                    [NSNumber numberWithInt:DEFAULT_BUILDING_MAX_WIDTH], @"BuildingWidthMax",
                                    [NSNumber numberWithInt:DEFAULT_STAR_DENSITY], @"StarDensity",
                                    [NSNumber numberWithInt:DEFAULT_REFRESH_TIME], @"RefreshTime",
                                    nil]];
        NSLog(@"STARRY: initWithFrame: defaults.BuildingHeight = %d",(int)[defaults floatForKey:@"BuildingHeight"]);
        
        starsPerUpdate = 12;
        // Note: Evan dropped buildingPixelsPerUpdate from 15 to 12 in his last update: https://github.com/evangreen/starryn/commit/1e310ca444f827cbc7af10c52e1400187ecb33fd
        buildingPixelsPerUpdate = 12;
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
        // NOTE: ARC is enabled in the project now, which means I don't need to dealloc?
        drawnStarPoints = [[NSMutableArray alloc] initWithCapacity:10000];
        drawnBuildingPoints = [[NSMutableArray alloc] initWithCapacity:10000];
        maxDrawnStarPoints = 10000; // we'll re-adjust these based on view size when view bounds get set
        maxDrawnBuildingPoints = 10000;
        
        // Allocate our single workPath
        workPath = [[NSBezierPath alloc] init];
        
        // Set our refresh timer to nil, set in deferredInitialization later
        refreshTimer = nil;
        
        // Defer the rest of the initialization, which requires an accurate view bounds which hasn't
        // been set yet
        instanceIsInitialized = NO;
        
    }
    return self;
}

- (void)dealloc
{
    // Most cleanup should be done by ARC now
//    [buildingArray release];
//    [drawnStarPoints release];
//    [drawnBuildingPoints release];
//    [workPath release];
    if (refreshTimer != nil) {
        [refreshTimer invalidate];
        refreshTimer = nil;
    }
//    [super dealloc];
}

- (void)startAnimation
{
    [super startAnimation];
}

- (void)stopAnimation
{
    [super stopAnimation];
}

- (void)drawRect:(NSRect)rect
{
    [super drawRect:rect];
    
    if (! instanceIsInitialized) {
        if (self.frame.size.width <= 0 || self.frame.size.height <= 0) {
            NSLog(@"STARRY: Badness, getting to drawRect with 0 frame size?");
        }
        [self deferredInitialization];
    }
    // We're not using CALayer backed views, so drawRect will get called.
    // We can draw our view here, or in animateOneFrame (the latter getting
    // called at regular timer intervals, whereas drawRect only gets called
    // if we've marked the view as needing an update via [self setNeedsDisplay:YES])

    // Make our cachedBitmap the current draw context
    [NSGraphicsContext saveGraphicsState];
    NSGraphicsContext *ctx = [NSGraphicsContext graphicsContextWithBitmapImageRep:self->cachedBitmap];
    NSAssert(ctx, nil);
    [NSGraphicsContext setCurrentContext:ctx];
       
    // Draw all the elements (into our bitmap)
    [self drawStars];
    [self drawBuildings];
//    [self drawRain];
    [self drawShootingStar];
    [self drawFlasher];
      
    [[NSGraphicsContext currentContext] flushGraphics];

    // Restore view drawing context and draw our bitmap
    [NSGraphicsContext restoreGraphicsState];
    [self->cachedBitmap drawInRect:self.bounds];
    [[NSGraphicsContext currentContext] flushGraphics];
}

- (void)animateOneFrame
{
    // We should have a valid frame by this point, so do deferred init if necessary
    if (! instanceIsInitialized) {
        if (self.frame.size.width <= 0 || self.frame.size.height <= 0) {
            NSLog(@"STARRY: Badness, getting to animateOneFrame with 0 frame size?");
        }
        [self deferredInitialization];
    }

    // Flag that our drawRect should be called
    [self setNeedsDisplay:YES];
    return;
}

- (void)deferredInitialization {
    // Defer init until drawtime as we might not have an accurate view bounds until then
    
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
    float refreshTime = 0.0;
    
    ScreenSaverDefaults *defaults = [ScreenSaverDefaults defaultsForModuleWithName:MyModuleName];
    
    // Create our cached bitmap
    // If self.bounds is below a certain min size (e.g. the preview bounds)
    // generate a min-size bitmap, which will get scaled later in drawInRect
    // TODO: Might want to use self.visibleRect instead of self.bounds?
    cachedBitmapScale = 1.0;
    if (self.bounds.size.width < MIN_BITMAP_WIDTH) {
        cachedBitmapScale = MIN_BITMAP_WIDTH / self.bounds.size.width;
        cachedBitmapRect.size.width = MIN_BITMAP_WIDTH;
        cachedBitmapRect.size.height = self.bounds.size.height * (int)cachedBitmapScale;
        cachedBitmapRect.origin.x = 0;
        cachedBitmapRect.origin.y = 0;
        self->cachedBitmap = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:nil
                                                            pixelsWide:cachedBitmapRect.size.width
                                                            pixelsHigh:cachedBitmapRect.size.height
                                                         bitsPerSample:8
                                                       samplesPerPixel:4
                                                              hasAlpha:YES
                                                              isPlanar:NO
                                                        colorSpaceName:NSCalibratedRGBColorSpace
                                                          bitmapFormat:0
                                                           bytesPerRow:(4 * cachedBitmapRect.size.width)
                                                          bitsPerPixel:32];
    } else {
        cachedBitmapRect = self.bounds;
        self->cachedBitmap = [self bitmapImageRepForCachingDisplayInRect:cachedBitmapRect];
    }
   
    // Clear main view (in case we got here due to configOk)
    [NSGraphicsContext saveGraphicsState];
    NSGraphicsContext *ctx = [NSGraphicsContext graphicsContextWithBitmapImageRep:self->cachedBitmap];
    [NSGraphicsContext setCurrentContext:ctx];
    NSBezierPath * path = [NSBezierPath bezierPathWithRect:cachedBitmapRect];
    [[NSColor blackColor] set];
    [path fill];
    [[NSGraphicsContext currentContext] flushGraphics];
    [NSGraphicsContext restoreGraphicsState];
    
    float buildingHeightPercentage = [defaults floatForKey:@"BuildingHeight"] / 100.0;
    if (buildingHeightPercentage <= 0) {
        NSLog(@"STARRY: buildingHeightPercentage %f",buildingHeightPercentage);
        buildingHeightPercentage = DEFAULT_BUILDING_HEIGHT / 100.0;
    }

    // Determine the maximum height of a building
    maxHeight = (cachedBitmapRect.size.height * buildingHeightPercentage) / TILE_HEIGHT;
    
    minBuildingWidth = (int)[defaults integerForKey:@"BuildingWidthMin"];
    maxBuildingWidth = (int)[defaults integerForKey:@"BuildingWidthMax"];
    // Sanity check
    if (minBuildingWidth <= 0 || maxBuildingWidth <= 0) {
        NSLog(@"STARRY: buildingWidth Min Max %i %i", minBuildingWidth, maxBuildingWidth);
        minBuildingWidth = DEFAULT_BUILDING_MIN_WIDTH;
        maxBuildingWidth = DEFAULT_BUILDING_MAX_WIDTH;
    }
    if (maxBuildingWidth < minBuildingWidth) {
        maxBuildingWidth = minBuildingWidth + 1;
    }
    
    // Allocate and initialize the buildings
    flasherBuilding = 0;
    workBuildingCount = (int)[defaults integerForKey:@"BuildingCount"];
    if (workBuildingCount <= 0) {
        NSLog(@"STARRY: buildingCount %i", workBuildingCount);
        workBuildingCount = DEFAULT_BUILDING_COUNT;
    }

    NSMutableData *workBuildingArray = [[NSMutableData alloc] initWithLength:sizeof(MCP_StarryNight_BUILDING) * workBuildingCount];
    maxActualHeight = 0;
    MCP_StarryNight_BUILDING* array = [workBuildingArray mutableBytes];
    for (buildingIndex = 0; buildingIndex < workBuildingCount; buildingIndex++) {
        array[buildingIndex].style = rand() % BUILDING_STYLE_COUNT;
        // Squaring the random height makes for a more interesting distribution
        // of buildings.
        randomHeight = (float)rand() / (float)RAND_MAX;
        array[buildingIndex].height = randomHeight * randomHeight * (float)maxHeight;
        if (array[buildingIndex].height < 5) {
            // Set min building height to 5 pixels
            array[buildingIndex].height = 5;
        }
        array[buildingIndex].width = minBuildingWidth + (rand() % (maxBuildingWidth - minBuildingWidth));
        array[buildingIndex].beginX = rand() % (int)(cachedBitmapRect.size.width);
        array[buildingIndex].zCoordinate = buildingIndex + 1; // ???
        if (array[buildingIndex].height > maxActualHeight) {
            maxActualHeight = (int)array[buildingIndex].height;
            flasherBuilding = buildingIndex;
        }
    }
    
    // Determine the flasher coordinates. The flasher goes at the center of the
    // top of the tallest building.
    flasherX = (int)array[flasherBuilding].beginX + (int)(array[flasherBuilding].width * TILE_WIDTH / 2);
    flasherY = cachedBitmapRect.size.height - (array[flasherBuilding].height * TILE_HEIGHT);
    
    // Sort the buildings by X coordinate.
    for (buildingIndex = 0; buildingIndex < workBuildingCount - 1; buildingIndex++) {
        // Find the building with the lowest X coordinate.
        minX = cachedBitmapRect.size.width;
        minXIndex = -1;
        for (index2 = buildingIndex; index2 < workBuildingCount; index2 += 1) {
            if (array[index2].beginX < minX) {
                minX = (int)array[index2].beginX;
                minXIndex = index2;
            }
        }
        // Swap it into position.
        if (buildingIndex != minXIndex) {
            swap = array[buildingIndex];
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
    if (starDensityPercentage <= 0.0) {
        NSLog(@"STARRY: starDensityPercentage %f", starDensityPercentage);
        starDensityPercentage = DEFAULT_STAR_DENSITY / 100.0;
    }

    maxDrawnStarPoints = (cachedBitmapRect.size.width * cachedBitmapRect.size.height) * starDensityPercentage;
    maxDrawnBuildingPoints = (cachedBitmapRect.size.width * cachedBitmapRect.size.height) * 0.20;
    // sanity check
    if (maxDrawnStarPoints <= 0) {
        maxDrawnStarPoints = starsPerUpdate;
    }
    if (maxDrawnBuildingPoints <= 0) {
        maxDrawnBuildingPoints = buildingPixelsPerUpdate;
    }
    
    refreshTime = (float)[defaults integerForKey:@"RefreshTime"] * 60.0;
    if (refreshTime > 0.0) {
        refreshTimer = [NSTimer scheduledTimerWithTimeInterval:refreshTime
                                                        target:self
                                                      selector:@selector(refreshTimerCalled)
                                                      userInfo:nil repeats:NO];
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
        starX = rand() % (int)cachedBitmapRect.size.width;
        
        // Squaring the Y coordinate puts more stars at the top and gives it
        // a more realistic (and less static-ish) view.
        
        randomY = (float)rand() / (float)RAND_MAX;
        starY = (int)(randomY * randomY * (float)cachedBitmapRect.size.height);
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
    
    buildingHeightRange = cachedBitmapRect.size.height - flasherY;
    buildingHeightOffset = flasherY;
    pixelsOn = 0;
    while (pixelsOn < buildingPixelsPerUpdate) {
        potentialX = rand() % (int)cachedBitmapRect.size.width;
        potentialY = buildingHeightOffset + (rand() % buildingHeightRange);
        building = [self getTopBuildingForScreenX:potentialX andScreenY:potentialY];
        if (building == -1) {
            continue;
        }
        
        tileX = (potentialX - array[building].beginX) % TILE_WIDTH;
        tileY = potentialY % TILE_HEIGHT;
        style = (int)array[building].style;
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
    [workPath setLineCapStyle:NSLineCapStyleRound];
    [workPath setLineJoinStyle:NSLineJoinStyleRound];
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
    
    flasherTime += 30; // assume approx 50 [now 30] ms have elapsed with each animateOneFrame call
    if (flasherTime >= flasherPeriodMs) {
        flasherTime -= flasherPeriodMs;
        if (! flasherOn) {
            flasherOn = YES;
            blackOutFlasher = NO;
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
        [workPath setLineCapStyle:NSLineCapStyleRound];
        [workPath setLineJoinStyle:NSLineJoinStyleRound];
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
    int buildingCount;
    
    ScreenSaverDefaults *defaults = [ScreenSaverDefaults defaultsForModuleWithName:MyModuleName];
    const MCP_StarryNight_BUILDING* array = [buildingArray bytes];
    
    frontBuilding = -1;
    maxZ = 0;
    buildingCount = (int)[defaults integerForKey:@"BuildingCount"];
    if (buildingCount <= 0) {
        //NSLog(@"STARRY: getTopBuildingForScreenX: buildingCount = %i", buildingCount);
        buildingCount = DEFAULT_BUILDING_COUNT;
    }
    for (building = 0; building < buildingCount; building += 1) {

        // The buildings are sorted by X coordinate. If this building starts
        // to the right of the pixel in question, none of the rest intersect.
        
        if (array[building].beginX > screenX) {
            break;
        }
        
        // Check to see if the pixel is inside this building.
        
        buildingTop = cachedBitmapRect.size.height - (array[building].height * TILE_HEIGHT);
        buildingRight = (int)array[building].beginX + (int)(array[building].width * TILE_WIDTH);
        
        if ((screenX >= array[building].beginX) &&
            (screenX < buildingRight) &&
            (screenY > buildingTop)) {
            
            // If this is the front-most building, mark it as the new winner.
            
            if (array[building].zCoordinate > maxZ) {
                frontBuilding = building;
                maxZ = (int)array[building].zCoordinate;
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
- (BOOL)isFlipped {
    // Flip drawing coordinates
    return YES;
}

#pragma mark Configure Sheet methods

- (BOOL)hasConfigureSheet
{
    return YES;
}

- (NSWindow*)configureSheet
{
    NSBundle *thisBundle = [NSBundle bundleForClass:[self class]];
    if (![thisBundle loadNibNamed:@"ConfigureSheet" owner:self topLevelObjects:NULL]) {
        NSLog(@"STARRY: Unable to load configuration sheet");
    }
    
    ScreenSaverDefaults *defaults = [ScreenSaverDefaults defaultsForModuleWithName:MyModuleName];

    [configVersion setStringValue:[defaults stringForKey:@"Version"]];
    int buildingHeight = (int)[defaults integerForKey:@"BuildingHeight"];
    NSString *buildingHeightString = @"Building Height";
    [configBuildingHeightLabel setStringValue:[buildingHeightString stringByAppendingFormat:@" (%d):", buildingHeight]];
    [configBuildingHeight setIntValue:buildingHeight];
    int buildingCount = (int)[defaults integerForKey:@"BuildingCount"];
    NSString *buildingCountString = @"Building Count";
    [configBuildingCountLabel setStringValue:[buildingCountString stringByAppendingFormat:@" (%d):", buildingCount]];
    [configBuildingCount setIntValue:buildingCount];
    [configFlasher setState:[defaults boolForKey:@"FlasherEnabled"]];
    [configRetroColor setState:[defaults boolForKey:@"RetroColorEnabled"]];
    int buildingMin = (int)[defaults integerForKey:@"BuildingWidthMin"];
    NSString *buildingMinString = @"Building Width Min";
    [configBuildingWidthMinLabel setStringValue:[buildingMinString stringByAppendingFormat:@" (%d):", buildingMin]];
    [configBuildingWidthMin setIntValue:buildingMin];
    int buildingMax = (int)[defaults integerForKey:@"BuildingWidthMax"];
    NSString *buildingMaxString = @"Building Width Max";
    [configBuildingWidthMaxLabel setStringValue:[buildingMaxString stringByAppendingFormat:@" (%d):", buildingMax]];
    [configBuildingWidthMax setIntValue:buildingMax];
    int starDensity = (int)[defaults integerForKey:@"StarDensity"];
    NSString *starDensityString = @"Star Density";
    [configStarDensityLabel setStringValue:[starDensityString stringByAppendingFormat:@" (%d):", starDensity]];
    [configStarDensity setIntValue:starDensity];
    int refreshTime = (int)[defaults integerForKey:@"RefreshTime"];
    [configRefreshTime setIntValue:refreshTime];
    NSString *refreshTimeString = @"Refresh Time";
    if (refreshTime <= 0) {
        refreshTimeString = [refreshTimeString stringByAppendingString:@" (no refresh)"];
    } else {
        refreshTimeString = [refreshTimeString stringByAppendingFormat:@" (%d minutes)", refreshTime];
    }
    [configRefreshTimeLabel setStringValue:refreshTimeString];
    
    // Sometimes, on the very first load, our defaults are basically unset (so somehow
    // this is being called before initWithFrame?) If values like BuildingWidthMin & Max are 0,
    // set UI to our defaults instead.
    if ([defaults integerForKey:@"BuildingHeight"] == 0 && [defaults integerForKey:@"BuildingWidthMin"] == 0 && [defaults integerForKey:@"BuildingWidthMax"] == 0) {
        NSLog(@"STARRY: Bad defaults when loading configure sheet, replacing with canned defaults");
        [configVersion setStringValue:@"1.01"];
        [configBuildingHeight setIntValue:DEFAULT_BUILDING_HEIGHT];
        [configBuildingHeightLabel setStringValue:[buildingHeightString stringByAppendingFormat:@" (%d):", DEFAULT_BUILDING_HEIGHT]];
        [configBuildingCount setIntValue:DEFAULT_BUILDING_COUNT];
        [configBuildingCountLabel setStringValue:[buildingCountString stringByAppendingFormat:@" (%d):", DEFAULT_BUILDING_HEIGHT]];
        [configFlasher setState:YES];
        [configRetroColor setState:NO];
        [configBuildingWidthMin setIntValue:DEFAULT_BUILDING_MIN_WIDTH];
        [configBuildingWidthMinLabel setStringValue:[buildingMinString stringByAppendingFormat:@" (%d):", DEFAULT_BUILDING_MIN_WIDTH]];
        [configBuildingWidthMax setIntValue:DEFAULT_BUILDING_MAX_WIDTH];
        [configBuildingWidthMaxLabel setStringValue:[buildingMaxString stringByAppendingFormat:@" (%d):", DEFAULT_BUILDING_MAX_WIDTH]];
        [configStarDensity setIntValue:DEFAULT_STAR_DENSITY];
        [configStarDensityLabel setStringValue:[starDensityString stringByAppendingFormat:@" (%d):", DEFAULT_STAR_DENSITY]];
        [configRefreshTime setIntValue:DEFAULT_REFRESH_TIME];
        refreshTimeString = [refreshTimeString stringByAppendingFormat:@" (%d minutes):", DEFAULT_REFRESH_TIME];
        [configRefreshTimeLabel setStringValue:refreshTimeString];
    }
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
    [defaults setInteger:[configRefreshTime intValue] forKey:@"RefreshTime"];

    // save defaults to disk
    [defaults synchronize];

    // Clear any existing preview
    instanceIsInitialized = NO;
    [drawnStarPoints removeAllObjects];
    [drawnBuildingPoints removeAllObjects];
//    //[buildingArray release]; Hopefully with ARC enabled this will get free'd when we re-alloc in deferredInitialization
    [workPath removeAllPoints];

    [[NSApplication sharedApplication] endSheet:configSheet];
}

- (IBAction)configBuildingHeightSliderChanged:(id)sender
{
    int newBuildingHeightVal = [configBuildingHeight intValue];
    NSString *newBuildingHeightString = @"Building Height";
    [configBuildingHeightLabel setStringValue:[newBuildingHeightString stringByAppendingFormat:@" (%d):", newBuildingHeightVal]];
}

- (IBAction)configBuildingCountSliderChanged:(id)sender
{
    int newBuildingCountVal = [configBuildingCount intValue];
    NSString *newBuildingCountString = @"Building Count";
    [configBuildingCountLabel setStringValue:[newBuildingCountString stringByAppendingFormat:@" (%d):", newBuildingCountVal]];
}

- (IBAction)configBuildingWidthMinSliderChanged:(id)sender
{
    int newBuildingMinVal = [configBuildingWidthMin intValue];
    NSString *newBuildingMinString = @"Building Width Min";
    [configBuildingWidthMinLabel setStringValue:[newBuildingMinString stringByAppendingFormat:@" (%d):", newBuildingMinVal]];
}

- (IBAction)configBuildingWidthMaxSliderChanged:(id)sender
{
    int newBuildingMaxVal = [configBuildingWidthMax intValue];
    NSString *newBuildingMaxString = @"Building Width Max";
    [configBuildingWidthMaxLabel setStringValue:[newBuildingMaxString stringByAppendingFormat:@" (%d):", newBuildingMaxVal]];
}

- (IBAction)configStarDensitySliderChanged:(id)sender
{
    int newStarDensityVal = [configStarDensity intValue];
    NSString *newStarDensityString = @"Star Density";
    [configStarDensityLabel setStringValue:[newStarDensityString stringByAppendingFormat:@" (%d):", newStarDensityVal]];
}

- (IBAction)refreshSliderChanged:(id)sender
{
    int newRefreshVal = [configRefreshTime intValue];
    NSString *refreshTimeString = @"Refresh Time";
    if (newRefreshVal <= 0) {
        refreshTimeString = [refreshTimeString stringByAppendingString:@" (no refresh)"];
    } else {
        refreshTimeString = [refreshTimeString stringByAppendingFormat:@" (%d minutes)", newRefreshVal];
    }
    [configRefreshTimeLabel setStringValue:refreshTimeString];
}

#pragma mark Timer methods

- (void)refreshTimerCalled
{
    NSLog(@"STARRY: refresh timer called");
    
    instanceIsInitialized = NO;
    [drawnStarPoints removeAllObjects];
    [drawnBuildingPoints removeAllObjects];
//    //[buildingArray release]; Hopefully with ARC enabled this will get free'd when we re-alloc in deferredInitialization
    [workPath removeAllPoints];
}


@end
