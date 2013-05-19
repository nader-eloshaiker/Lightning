//
//  Lightning.h
//  Maze Mouse
//
//  Created by Nader Eloshaiker on 15/05/13.
//  Copyright 2013 Nader Eloshaiker. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"
#import "LightningStrikeDelegate.h"



typedef struct _ccV2F_T2F
{
    //! vertices (2F)
    ccVertex2F		vertices;
    //! tex coords (2F)
    ccTex2F			texCoords;
} ccV2F_T2F;



@interface Lightning : CCNode<CCRGBAProtocol, CCTextureProtocol> {
    ccV2F_T2F *_lightningVertices;
    GLuint _lightningVAOName;
    GLuint _lightningBuffersVBO;
    unsigned int _lightningBuffersCapacity;
    CGPoint *_pointVertices;
    NSUInteger _noOfPoints;
    NSUInteger _noOfInitialPoints;
    
    NSUInteger _seed;
    
    GLuint _colorLocation;
    ccColor3B _realColor;
    GLubyte _realOpacity;
    
    ccColor3B _displayedColor;
    GLubyte _displayedOpacity;
    BOOL _cascadeColorEnabled;
    BOOL _cascadeOpacityEnabled;
    
    CCTexture2D *_texture;
    ccBlendFunc _blendFunc;
    BOOL _opacityModifyRGB;
    BOOL _wasCapacityIncreased;
    
    Lightning *_splitLightning;
    ccTime _duration;
    ccTime _fadeDuration;
    BOOL _autoRemoveFromParent;
    
    id<LightningStrikeDelegate> _delegate;
}


@property(nonatomic, readwrite) CGPoint strikeSource;
@property(nonatomic, readwrite) CGPoint strikeSplitDestination;
@property(nonatomic, readwrite) CGPoint strikeDestination;

@property(nonatomic, readwrite) ccColor3B color;
@property(nonatomic, readwrite) GLubyte opacity;

@property(nonatomic, readonly) ccColor3B displayedColor;
@property(nonatomic, readonly) GLubyte displayedOpacity;
@property(nonatomic, getter = isCascadeColorEnabled) BOOL cascadeColorEnabled;
@property(nonatomic, getter = isCascadeOpacityEnabled) BOOL cascadeOpacityEnabled;
@property(nonatomic, getter = isAutoRemoveFromParent) BOOL autoRemoveFromParent;
@property(nonatomic, readwrite, retain) id<LightningStrikeDelegate> delegate;


@property(nonatomic, readwrite) BOOL split;
@property(nonatomic, readwrite) NSInteger displacement;
@property(nonatomic, readwrite) NSInteger minDisplacement;
@property(nonatomic, readwrite) float lightningWidth;
@property(nonatomic, readwrite) ccTime fadeDuration;
@property(nonatomic, readwrite) ccTime duration;
@property(nonatomic, readwrite) ccBlendFunc blendFunc;

+(id) lightningWithStrikePoint:(CGPoint)source strikePoint2:(CGPoint)destination duration:(ccTime)duration fadeDuration:(ccTime)fadeDuration textureName:(NSString*)texturename;
+(id) lightningWithStrikePoint:(CGPoint)source strikePoint2:(CGPoint)destination duration:(ccTime)duration fadeDuration:(ccTime)fadeDuration texture:(CCTexture2D*)texture;
-(id)initWithStrikePoint:(CGPoint)source strikePoint2:(CGPoint)destination duration:(ccTime)duration fadeDuration:(ccTime)fadeDuration textureName:(NSString*)texturename;
-(id)initWithStrikePoint:(CGPoint)source strikePoint2:(CGPoint)destination duration:(ccTime)duration fadeDuration:(ccTime)fadeDuration texture:(CCTexture2D*)texture;

-(void)strikeRandom;
-(void)strikeWithSeed:(NSInteger)seed;
-(void)strike;
-(void)setInitialPoints:(CGPoint *)initialPoints noOfInitialPoints:(NSUInteger)noOfInitialPoints;
-(void)setOpacityModifyRGB:(BOOL)modify;
@end