//
//  GameController.h
//  UntoldEngine
//
//  Created by Harold Serrano on 6/10/13.
//  Copyright (c) 2013 Untold Engine Studios. All rights reserved.
//

#ifndef __UntoldEngine__GameController__
#define __UntoldEngine__GameController__

#include <iostream>
#include "U4DTouchesController.h"
#include "U4DVector3n.h"
#include "UserCommonProtocols.h"
#include "U4DInteractiveEntity.h"

class GameController:public U4DEngine::U4DTouchesController{
  
private:

    U4DEngine::U4DJoyStick *joyStick;
    U4DEngine::U4DButton *myButtonA;
    U4DEngine::U4DButton *myButtonB;
    
    U4DInteractiveEntity *interactiveChest;
    U4DInteractiveEntity *interactiveDoor;
    U4DInteractiveEntity *interactiveCharacter;
    
public:
    
    GameController(){};
    
    
    ~GameController(){};
    
    void init();
    
    void setupInteractiveObjects();
    
    void actionOnButtonA();
    
    void actionOnButtonB();
    
    void actionOnJoystick();
    
    void examineChest();
    void openChest();
    void pickUpFromChest();
    
    void examineDoor();
    void openDoor();
    
    void examineCharacter();
    void talkToCharacter();

};

#endif /* defined(__UntoldEngine__GameController__) */
