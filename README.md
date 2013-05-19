Lightning
=========

Cocos2D Lightning Effect

I have ported the Lighting code to Cocos2D v2.1 based on the original code provided.


Original code by:

Robert Blackwood on 12/1/09.

Copyright 2009 Mobile Bros. All rights reserved.


Migration to shaders (Cocos2D v2.0) by 

kheldorin http://www.cocos2d-iphone.org/forum/profile/97134


Usage:

l.strikeSource = ccp(400, 320);

l.strikeSplitDestination = ccp(200, 0);

l.strikeDestination = ccp(200 + 300, 0);


//random color

l.color = ccc3(CCRANDOM_0_1() * 255, CCRANDOM_0_1() * 255, 255);

l.opacity = 50;


//random style

l.displacement = 100 + CCRANDOM_0_1() * 50;

l.minDisplacement = 1 + CCRANDOM_0_1() * 5;

l.lightningWidth = 4.0f + CCRANDOM_MINUS1_1() * 2;

l.split = YES;


//call strike

[l strikeRandom];
