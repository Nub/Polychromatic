//
//  PLYVariableManager.m
//  Polychromatic
//
//  Created by Kolin Krewinkel on 3/11/14.
//  Copyright (c) 2014 Kolin Krewinkel. All rights reserved.
//

#import "PLYVariableManager.h"
#import "DVTInterfaces.h"

#import "DVTFontAndColorTheme+PLYDataInjection.h"

static NSString *const IDEIndexDidIndexWorkspaceNotification = @"IDEIndexDidIndexWorkspaceNotification";

@interface PLYVariableManager ()

@property (nonatomic, strong) NSMutableDictionary *workspaces;
@property (nonatomic, strong) NSMutableDictionary *workspaceColorOffset;

@end

@implementation PLYVariableManager

- (CGFloat)hue_offset:(NSUInteger)index forWorkSpace:(IDEWorkspace*)workSpace {
	float offset = 0.f;
	
	if (!self.workspaceColorOffset[workSpace.name]) {
		self.workspaceColorOffset[workSpace.name] = @0;
	}
	
	NSInteger offset_level = [self.workspaceColorOffset[workSpace.name] integerValue];
	
	if (offset_level == 0) {
		goto end;
	}
	
	int swing = index % 2;
	
	if (swing) {
		offset = 1.f + sin(index);
	} else {
		offset = 1.f + cos(index);
	}
	
	offset /= 2.f;
	
end:
	offset_level ++;
	self.workspaceColorOffset[workSpace.name] = @(offset_level);
	return offset;
}

#pragma mark - Singleton

+ (instancetype)sharedManager
{
    static dispatch_once_t onceToken;
    static id sharedManager;
    dispatch_once(&onceToken, ^{
        sharedManager = [[self alloc] init];
    });

    return sharedManager;
}

#pragma mark - Initialization

- (id)init
{
    if ((self = [super init]))
    {
        self.workspaces = [[NSMutableDictionary alloc] init];
		self.workspaceColorOffset = [NSMutableDictionary new];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(indexDidIndexWorkspaceNotification:) name:IDEIndexDidIndexWorkspaceNotification object:nil];
    }

    return self;
}

#pragma mark - Variable Management

- (NSMutableOrderedSet *)variableSetForWorkspace:(IDEWorkspace *)workspace
{
    return self.workspaces[workspace.filePath.pathString];
}

- (NSColor *)colorForVariable:(NSString *)variable inWorkspace:(IDEWorkspace *)workspace
{
    NSMutableOrderedSet *variables = [self variableSetForWorkspace:workspace];

    if (!variables && workspace.filePath.pathString)
    {
        variables = [[NSMutableOrderedSet alloc] init];
        [self.workspaces setObject:variables forKey:workspace.filePath.pathString];
    }

    if (![variables containsObject:variable])
    {
        [variables addObject:variable];
//		[variables sortUsingDescriptors:@[[[NSSortDescriptor alloc] initWithKey:@"self" ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)]]];
    }

    NSUInteger index = [variables indexOfObject:variable];

	CGFloat hueValue = [self hue_offset:index forWorkSpace:workspace];
	NSColor* color = [NSColor colorWithCalibratedHue:hueValue saturation:[[DVTFontAndColorTheme currentTheme] ply_saturation] brightness:[[DVTFontAndColorTheme currentTheme] ply_brightness] alpha:1.f];
	if (!color) {
		[NSColor grayColor];
	}
    return color;
}

- (void)indexDidIndexWorkspaceNotification:(NSNotification *)notification
{
    IDEIndex *index = notification.object;
    IDEWorkspace *workspace = [index valueForKey:@"_workspace"];

    [[self variableSetForWorkspace:workspace] removeAllObjects];
}

@end