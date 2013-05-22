//
//  Lightning.m
//  Maze Mouse
//
//  Created by Nader Eloshaiker on 15/05/13.
//  Copyright 2013 Nader Eloshaiker. All rights reserved.
//

#import "Lightning.h"
#import "CCVertex.h"



void ccVertexTexLineToPolygon(CGPoint *points, float stroke, ccV2F_T2F *vertices, NSUInteger offset, NSUInteger nuPoints) {
    
    nuPoints += offset;
    if(nuPoints<=1) return;
    
    stroke *= 0.5f;
    
    NSUInteger idx;
    NSUInteger nuPointsMinus = nuPoints-1;
    
    for(NSUInteger i = offset; i<nuPoints; i++) {
        idx = i*2;
        CGPoint p1 = points[i];
        CGPoint perpVector;
        
        if(i == 0)
            perpVector = ccpPerp(ccpNormalize(ccpSub(p1, points[i+1])));
        else if(i == nuPointsMinus)
            perpVector = ccpPerp(ccpNormalize(ccpSub(points[i-1], p1)));
        else {
            CGPoint p2 = points[i+1];
            CGPoint p0 = points[i-1];
            
            CGPoint p2p1 = ccpNormalize(ccpSub(p2, p1));
            CGPoint p0p1 = ccpNormalize(ccpSub(p0, p1));
            
            // Calculate angle between vectors
            float angle = acosf(ccpDot(p2p1, p0p1));
            
            if(angle < CC_DEGREES_TO_RADIANS(70))
                perpVector = ccpPerp(ccpNormalize(ccpMidpoint(p2p1, p0p1)));
            else if(angle < CC_DEGREES_TO_RADIANS(170))
                perpVector = ccpNormalize(ccpMidpoint(p2p1, p0p1));
            else
                perpVector = ccpPerp(ccpNormalize(ccpSub(p2, p0)));
        }
        
        perpVector = ccpMult(perpVector, stroke);
        
        vertices[idx].vertices = (ccVertex2F) {p1.x+perpVector.x, p1.y+perpVector.y};
        vertices[idx+1].vertices = (ccVertex2F) {p1.x-perpVector.x, p1.y-perpVector.y};
    }
    
    // Validate vertexes
    offset = (offset==0) ? 0 : offset-1;
    for(NSUInteger i = offset; i<nuPointsMinus; i++) {
        idx = i*2;
        const NSUInteger idx1 = idx+2;
        
        ccVertex2F p1 = vertices[idx].vertices;
        ccVertex2F p2 = vertices[idx+1].vertices;
        ccVertex2F p3 = vertices[idx1].vertices;
        ccVertex2F p4 = vertices[idx1+1].vertices;
        
        float s;
        //BOOL fixVertex = !ccpLineIntersect(ccp(p1.x, p1.y), ccp(p4.x, p4.y), ccp(p2.x, p2.y), ccp(p3.x, p3.y), &s, &t);
        BOOL fixVertex = !ccVertexLineIntersect(p1.x, p1.y, p4.x, p4.y, p2.x, p2.y, p3.x, p3.y, &s);
        
        if(!fixVertex)
            if (s<0.0f || s>1.0f)
                fixVertex = YES;
        
        if(fixVertex) {
            vertices[idx1].vertices = p4;
            vertices[idx1+1].vertices = p3;
        }
    }
}


@implementation Lightning


@synthesize strikeSource = strikeSource_;
@synthesize strikeSplitDestination = strikeSplitDestination_;
@synthesize strikeDestination = strikeDestination_;
@synthesize displacement = displacement_;
@synthesize minDisplacement = minDisplacement_;
@synthesize lightningWidth = lightningWidth_;
@synthesize split = split_;
@synthesize fadeDuration = _fadeDuration;
@synthesize duration = _duration;
@synthesize autoRemoveFromParent = _autoRemoveFromParent;
@synthesize delegate = _delegate;
@synthesize cascadeColorEnabled = _cascadeColorEnabled;
@synthesize cascadeOpacityEnabled = _cascadeOpacityEnabled;



+(id)lightningWithStrikePoint:(CGPoint)source strikePoint2:(CGPoint)destination duration:(ccTime)duration fadeDuration:(ccTime)fadeDuration textureName:(NSString *)texturename {
    CCTexture2D *texture = [[CCTextureCache sharedTextureCache] addImage:texturename];
    return [[self alloc] initWithStrikePoint:source strikePoint2:destination duration:duration fadeDuration:fadeDuration texture:texture];
}

+(id)lightningWithStrikePoint:(CGPoint)source strikePoint2:(CGPoint)destination duration:(ccTime)duration fadeDuration:(ccTime)fadeDuration texture:(CCTexture2D *)texture {
    
    return [[self alloc] initWithStrikePoint:source strikePoint2:destination duration:duration fadeDuration:fadeDuration texture:texture];
}

-(id)initWithStrikePoint:(CGPoint)source strikePoint2:(CGPoint)destination duration:(ccTime)duration fadeDuration:(ccTime)fadeDuration textureName:(NSString *)texturename {
    
    CCTexture2D *texture = [[CCTextureCache sharedTextureCache] addImage:texturename];
    return [self initWithStrikePoint:source strikePoint2:destination duration:duration fadeDuration:fadeDuration texture:texture];
}

-(id)initWithStrikePoint:(CGPoint)source strikePoint2:(CGPoint)destination duration:(ccTime)duration fadeDuration:(ccTime)fadeDuration texture:(CCTexture2D *)texture {
    
    if (self = [super init]) {
		self.shaderProgram = [[CCShaderCache sharedShaderCache] programForKey:kCCShader_PositionTexture_uColor];
        _colorLocation = glGetUniformLocation( self.shaderProgram.program, "u_color");

        _displayedColor = _realColor = ccWHITE;
        _displayedOpacity = _realOpacity = 255;
        _cascadeOpacityEnabled = YES;
        _cascadeColorEnabled = YES;
        _autoRemoveFromParent = NO;
        _delegate = nil;

        _blendFunc = (ccBlendFunc) {CC_BLEND_SRC, CC_BLEND_DST};

        _texture = [texture retain];
        _opacityModifyRGB = NO;
        
        strikeSource_ = source;
        strikeSplitDestination_ = CGPointZero;
        strikeDestination_ = destination;
        
        _duration = duration;
        _fadeDuration = fadeDuration;
        
        split_ = NO;
        
        displacement_ = 120;
        minDisplacement_ = 4;
        lightningWidth_ = 1.0f;
        
        [self ensureCapacity:16];
        
        glGenVertexArrays(1, &_lightningVAOName);
        ccGLBindVAO(_lightningVAOName);
        
        glGenBuffers(1, &_lightningBuffersVBO);
        glBindBuffer(GL_ARRAY_BUFFER, _lightningBuffersVBO);
        glBufferData(GL_ARRAY_BUFFER, sizeof(ccV2F_T2F) * _lightningBuffersCapacity, _lightningVertices, GL_DYNAMIC_DRAW);
        
        glEnableVertexAttribArray(kCCVertexAttrib_Position);
        glVertexAttribPointer( kCCVertexAttrib_Position, 2, GL_FLOAT, GL_FALSE, sizeof(ccV2F_T2F), (GLvoid *)offsetof(ccV2F_T2F, vertices) );
        
        glEnableVertexAttribArray(kCCVertexAttrib_TexCoords);
        glVertexAttribPointer( kCCVertexAttrib_TexCoords, 2, GL_FLOAT, GL_FALSE, sizeof(ccV2F_T2F), (GLvoid *)offsetof(ccV2F_T2F, texCoords) );
        
        ccGLBindVAO(0);
        glBindBuffer(GL_ARRAY_BUFFER, 0);
        CHECK_GL_ERROR();
        _wasCapacityIncreased = NO;
        
    }
    
    return self;
}

-(BOOL) ensureCapacity:(NSUInteger)count {
    
    if ( count > _lightningBuffersCapacity) {
        _lightningBuffersCapacity = MAX(_lightningBuffersCapacity, count);
        _lightningVertices = (ccV2F_T2F *)realloc( _lightningVertices, _lightningBuffersCapacity * sizeof(ccV2F_T2F) );
        _pointVertices = (CGPoint *)realloc( _pointVertices, _lightningBuffersCapacity * 0.5f * sizeof(CGPoint) );
        return YES;
    }
    
    return NO;
}

-(void)draw {
    CC_NODE_DRAW_SETUP();
    
    ccGLBlendFunc( _blendFunc.src, _blendFunc.dst );
    ccColor4F floatColor = ccc4FFromccc3B(_displayedColor);
    floatColor.a = _realOpacity / 255.0f;
    [self.shaderProgram setUniformLocation:_colorLocation withF1:floatColor.r f2:floatColor.g f3:floatColor.b f4:floatColor.a];
    ccGLBindTexture2D( [_texture name] );
    
    ccGLBindVAO( _lightningVAOName );
    glDrawArrays(GL_TRIANGLE_STRIP, 0, (GLsizei)_noOfPoints * 2);
    CC_INCREMENT_GL_DRAWS(1);
}

-(void)strikeRandom {
    _seed = rand();
    [self strike];
}

-(void)strikeWithSeed:(NSInteger)seed {
    _seed = seed;
    [self strike];
}

-(void)setInitialPoints:(CGPoint *)initialPoints noOfInitialPoints:(NSUInteger)noOfInitialPoints {
    
    _noOfInitialPoints = noOfInitialPoints;
    _wasCapacityIncreased = [self ensureCapacity:noOfInitialPoints * 2];

    for (NSUInteger i = 0; i < _noOfInitialPoints; i++) {
        _pointVertices[i] = initialPoints[i];
    }
}

-(void)strike
{
    self.visible = NO;
    CCFiniteTimeAction *action, *fadeAction;
    
    if (_opacityModifyRGB) {
        fadeAction = [CCFadeTo actionWithDuration:_fadeDuration opacity:0];
    } else {
        CCTintTo *tintTo = [CCTintTo actionWithDuration:_fadeDuration red:0 green:0 blue:0];
        CCFadeTo *fadeTo = [CCFadeTo actionWithDuration:_fadeDuration opacity:0];
        fadeAction = [CCSpawn actionOne:tintTo two:fadeTo];
    }
    
    action = [CCSequence actions:
              [CCShow action],
              [CCDelayTime actionWithDuration:_duration],
              fadeAction,
              nil];
    
    if (_delegate) {
        action = [CCSequence actions:
                  [CCCallFuncN actionWithTarget:_delegate selector:@selector(actionLightingWillStrike)],
                  action,
                  [CCCallFuncN actionWithTarget:_delegate selector:@selector(actionLightingDidStrike)],
                  nil];
    }

    if (_autoRemoveFromParent) {
        action = [CCSequence actionOne:action two:[CCCallFuncND actionWithTarget:self selector:@selector(removeFromParentAndCleanup:) data:TRUE]];
    } else {
        action = [CCSequence actions:action,
                  [CCHide action],
                  [CCFadeTo actionWithDuration:0.0f opacity:_realOpacity],
                  [CCTintTo actionWithDuration:0.0f red:_realColor.r green:_realColor.g blue:_realColor.b],
                  nil];
    }
        
    [self runAction:action];
    
    srand(_seed);
    NSInteger noOfLines = [self computeNumberOfLines:strikeSource_ pt2:strikeDestination_ displace:displacement_ minDisplace:minDisplacement_];
    _noOfPoints = _noOfInitialPoints + noOfLines + 1;
    _wasCapacityIncreased = [self ensureCapacity:_noOfPoints * 2] || _wasCapacityIncreased;
    _noOfPoints = _noOfInitialPoints;
    srand(_seed);
    CGPoint mid = [self addLightning:strikeSource_ pt2:strikeDestination_ displace:displacement_ minDisplace:minDisplacement_];
    ccVertexTexLineToPolygon(_pointVertices, lightningWidth_, _lightningVertices, 0, _noOfPoints);
    float texDelta = 1.0f / _noOfPoints;

    for (NSUInteger i = 0; i < _noOfPoints; i++ ) {
        _lightningVertices[i * 2].texCoords = (ccTex2F) {0, texDelta * i};
        _lightningVertices[i * 2 + 1].texCoords = (ccTex2F) {1, texDelta * i};
    }
    
    glBindBuffer(GL_ARRAY_BUFFER, _lightningBuffersVBO );

    if (_wasCapacityIncreased) {
        glBufferData(GL_ARRAY_BUFFER, sizeof(ccV2F_T2F) * _noOfPoints * 2, _lightningVertices, GL_DYNAMIC_DRAW);
    } else {
        glBufferSubData(GL_ARRAY_BUFFER, 0, sizeof(ccV2F_T2F) * _noOfPoints * 2, _lightningVertices);
    }
    
    glBindBuffer(GL_ARRAY_BUFFER, 0);
    
    if (split_) {
        
        if (_splitLightning == 0) {
            _splitLightning = [[Lightning alloc] initWithStrikePoint:mid strikePoint2:strikeSplitDestination_ duration:_duration fadeDuration:_fadeDuration texture:_texture];
            [self addChild:_splitLightning z:-1];
        }
        
        _splitLightning.strikeSource = mid;
        _splitLightning.strikeDestination = strikeSplitDestination_;
        _splitLightning.minDisplacement = minDisplacement_;
        _splitLightning.displacement = displacement_ * 0.5f;
        _splitLightning.lightningWidth = lightningWidth_;
        _splitLightning.color = _realColor;
        _splitLightning.opacity = _realOpacity;
        _splitLightning.duration = _duration;
        _splitLightning.fadeDuration = _fadeDuration;
        [_splitLightning setOpacityModifyRGB:_opacityModifyRGB];
        [_splitLightning setInitialPoints:_pointVertices noOfInitialPoints:_noOfPoints * 0.5f + 1];
        [_splitLightning strikeWithSeed:_seed];
    }
    
    _wasCapacityIncreased = NO;
}

-(CGPoint)addLightning:(CGPoint)pt1 pt2:(CGPoint)pt2 displace:(NSInteger)displace minDisplace:(NSInteger)minDisplace {
    
    CGPoint mid = ccpMult(ccpAdd(pt1,pt2), 0.5f);
    
    if (displace < minDisplace) {
        
        if (_noOfPoints == 0) {
            _pointVertices[0] = pt1;
            _noOfPoints++;
        }
        
        _pointVertices[_noOfPoints] = pt2;
        _noOfPoints++;
        
    } else {
        
        mid.x += ( (rand() % 101) / 100.0f - 0.5f ) * displace;
        mid.y += ( (rand() % 101) / 100.0f - 0.5f ) * displace;
        
        [self addLightning:pt1 pt2:mid displace:displace * 0.5f minDisplace:minDisplace];
        [self addLightning:mid pt2:pt2 displace:displace * 0.5f minDisplace:minDisplace];
    }
    
    return mid;
}

-(NSUInteger)computeNumberOfLines:(CGPoint)pt1 pt2:(CGPoint)pt2 displace:(NSInteger)displace minDisplace:(NSInteger)minDisplace {
    
    CGPoint mid = ccpMult(ccpAdd(pt1,pt2), 0.5f);
    
    if (displace < minDisplace) {
        return 1;
    }
    
    mid.x += ( (rand() % 101) / 100.0f - 0.5f ) * displace;
    mid.y += ( (rand() % 101) / 100.0f - 0.5f ) * displace;
    
    return
    [self computeNumberOfLines:pt1 pt2:mid displace:displace * 0.5f minDisplace:minDisplace] +
    [self computeNumberOfLines:mid pt2:pt2 displace:displace * 0.5f minDisplace:minDisplace];
}

-(void)updateBlendFunc {
    
    if ( !_texture || ![_texture hasPremultipliedAlpha] ) {
        
        _blendFunc.src = GL_SRC_ALPHA;
        _blendFunc.dst = GL_ONE_MINUS_SRC_ALPHA;
        [self setOpacityModifyRGB:NO];
        
    } else {
        
        _blendFunc.src = CC_BLEND_SRC;
        _blendFunc.dst = CC_BLEND_DST;
    }
}

-(void)setTexture:(CCTexture2D *)texture {
    if ( _texture == texture )
        return;
    
    if (_texture) {
        [_texture release];
        _texture = nil;
    }
    
    _texture = [_texture retain];
    [self updateBlendFunc];

}

-(CCTexture2D *)texture {
    return _texture;
}

-(GLubyte) opacity {
    return _realOpacity;
}

-(void)setOpacity:(GLubyte)opacity {
    _displayedOpacity = _realOpacity = opacity;
    
	if( _cascadeOpacityEnabled ) {
		GLubyte parentOpacity = 255;
        
		if( [_parent conformsToProtocol:@protocol(CCRGBAProtocol)] && [(id<CCRGBAProtocol>)_parent isCascadeOpacityEnabled] ) {
            
			parentOpacity = [(id<CCRGBAProtocol>)_parent displayedOpacity];
        }
        
		[self updateDisplayedOpacity:parentOpacity];
	}

    
    // special opacity for premultiplied textures
    if ( _opacityModifyRGB ) {
        [self setColor:_realColor];
    }
}

-(ccColor3B)color {
    if (_opacityModifyRGB) {
        return _realColor;
    }
    
    return _displayedColor;
}

-(void)setColor:(ccColor3B)color3 {
    _displayedColor = _realColor = color3;
    
    if ( _opacityModifyRGB ) {
        _displayedColor.r = color3.r * _realOpacity / 255.0f;
        _displayedColor.g = color3.g * _realOpacity / 255.0f;
        _displayedColor.b = color3.b * _realOpacity / 255.0f;
    }
    
    if( _cascadeColorEnabled ) {
		ccColor3B parentColor = ccWHITE;
		if( [_parent conformsToProtocol:@protocol(CCRGBAProtocol)] && [(id<CCRGBAProtocol>)_parent isCascadeColorEnabled] )
			parentColor = [(id<CCRGBAProtocol>)_parent displayedColor];
		[self updateDisplayedColor:parentColor];
	}
}

-(void)setOpacityModifyRGB:(BOOL)modify {
    ccColor3B oldColor = self.color;
    _opacityModifyRGB = modify;
    self.color = oldColor;
}

-(BOOL) doesOpacityModifyRGB {
    return _opacityModifyRGB;
}

/** recursive method that updates display color */
-(void)updateDisplayedColor:(ccColor3B)parentColor {
	_displayedColor.r = _realColor.r * parentColor.r/255.0;
	_displayedColor.g = _realColor.g * parentColor.g/255.0;
	_displayedColor.b = _realColor.b * parentColor.b/255.0;
    
	CCSprite *item;
	CCARRAY_FOREACH(_children, item) {
		[item updateDisplayedColor:_displayedColor];
	}
}

/** recursive method that updates the displayed opacity */
-(void)updateDisplayedOpacity:(GLubyte)parentOpacity {
	_displayedOpacity = _realOpacity * parentOpacity/255.0;
    
	CCSprite *item;
	CCARRAY_FOREACH(_children, item) {
		[item updateDisplayedOpacity:_displayedOpacity];
	}
}

-(ccColor3B) displayedColor {
	return _displayedColor;
}

-(GLubyte) displayedOpacity {
	return _displayedOpacity;
}


-(void)dealloc {
    
    free(_lightningVertices);
    free(_pointVertices);
    glDeleteBuffers(0, &_lightningBuffersVBO);
    glDeleteBuffers(0, &_lightningVAOName);
    
    if (_delegate) {
        [_delegate release];
        _delegate = nil;
    }
    
    [super dealloc];
}



@end
