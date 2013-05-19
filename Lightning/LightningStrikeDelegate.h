//
//  LightningStrikeProtocol.h
//  Maze Mouse
//
//  Created by Nader Eloshaiker on 19/05/13.
//  Copyright (c) 2013 Nader Eloshaiker. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol LightningStrikeDelegate <NSObject>

@required
-(void)actionLightingWillStrike;
-(void)actionLightingDidStrike;
@end
