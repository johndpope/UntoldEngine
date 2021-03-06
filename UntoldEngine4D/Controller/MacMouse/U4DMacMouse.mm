//
//  U4DMacMouse.cpp
//  UntoldEngine
//
//  Created by Harold Serrano on 3/8/18.
//  Copyright © 2018 Untold Engine Studios. All rights reserved.
//

#include "U4DMacMouse.h"
#include "U4DDirector.h"
#include "U4DControllerInterface.h"
#include "U4DMacMouseStateManager.h"
#include "U4DMacMouseIdleState.h"
#include "U4DMacMousePressedState.h"
#include "U4DMacMouseActiveState.h"
#include "U4DMacMouseReleasedState.h"
#include "CommonProtocols.h"
#include "U4DVector2n.h"

namespace U4DEngine {
    
    
    U4DMacMouse::U4DMacMouse(MOUSEELEMENT &uMouseElementType):isActive(false),controllerInterface(NULL),pCallback(NULL),directionReversal(false),dataPosition(0.0,0.0,0.0),dataMagnitude(0.0),mouseAxis(0.0,0.0),initialDataPosition(0.0,0.0,0.0){
        
        stateManager=new U4DMacMouseStateManager(this);
        
        setEntityType(CONTROLLERINPUT);
        
        padElementType=uMouseElementType;
        
        //set initial state
        stateManager->changeState(U4DMacMouseIdleState::sharedInstance());
        
    }
    
    U4DMacMouse::~U4DMacMouse(){
        
        delete stateManager;
    }
    
    MOUSEELEMENT U4DMacMouse::getMouseElementType(){
        
        return padElementType;
        
    }
    
    void U4DMacMouse::setDataMagnitude(float uValue){
        
        dataMagnitude=uValue;
        
    }
    
    float U4DMacMouse::getDataMagnitude(){
        
        return dataMagnitude;
        
    }
    
    void U4DMacMouse::update(double dt){
        
        stateManager->update(dt);
        
    }
    
    void U4DMacMouse::action(){
        
        pCallback->action();
    }
    
    
    void U4DMacMouse::changeState(MOUSEACTION &uMouseAction, const U4DVector2n &uMouseAxis){
        
        if (uMouseAction==U4DEngine::mouseButtonPressed) {
            
            mouseAxis=uMouseAxis;
            
            stateManager->changeState(U4DMacMousePressedState::sharedInstance());
            
        }else if (uMouseAction==U4DEngine::mouseButtonDragged) {
            
            mouseAxis=uMouseAxis;
            
            stateManager->changeState(U4DMacMouseActiveState::sharedInstance());
            
        }else if(uMouseAction==U4DEngine::mouseButtonReleased && ((stateManager->getCurrentState()==U4DMacMouseActiveState::sharedInstance()) || (stateManager->getCurrentState()==U4DMacMousePressedState::sharedInstance()))){
            
            mouseAxis=U4DVector2n(0.0,0.0);
            
            stateManager->changeState(U4DMacMouseReleasedState::sharedInstance());
            
        }
        
    }
    
    
    void U4DMacMouse::setDataPosition(U4DVector3n uData){
        
        dataPosition=uData;
    }
    
    U4DVector3n U4DMacMouse::getDataPosition(){
        
        return dataPosition;
    }
    
    bool U4DMacMouse::getIsActive(){
        
        return (stateManager->getCurrentState()==U4DMacMouseActiveState::sharedInstance());;
    }
    
    void U4DMacMouse::setCallbackAction(U4DCallbackInterface *uAction){
        
        //set the callback
        pCallback=uAction;
        
    }
    
    void U4DMacMouse::setControllerInterface(U4DControllerInterface* uControllerInterface){
        
        controllerInterface=uControllerInterface;
        
    }
    
    bool U4DMacMouse::getDirectionReversal(){
        
        return directionReversal;
        
    }
    
}
