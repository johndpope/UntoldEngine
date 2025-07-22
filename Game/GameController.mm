//
//  GameController.cpp
//  UntoldEngine
//
//  Created by Harold Serrano on 6/10/13.
//  Copyright (c) 2013 Untold Engine Studios. All rights reserved.
//

#include "GameController.h"
#include <vector>
#include "CommonProtocols.h"
#include "GameLogic.h"
#include "U4DEntity.h"
#include "U4DCallback.h"
#include "U4DButton.h"
#include "U4DCamera.h"
#include "U4DJoyStick.h"
#include "Earth.h"
#include "U4DInteractiveEntity.h"
#include "U4DVerbCoinManager.h"

void GameController::init(){
    
    //get pointer to the earth
    Earth *earth=dynamic_cast<Earth*>(getGameWorld());
    
    joyStick=new U4DEngine::U4DJoyStick("joystick", -0.7,-0.6,"joyStickBackground.png",130,130,"joystickDriver.png",80,80);
    
    joyStick->setControllerInterface(this);
    
    earth->addChild(joyStick,-2);
    
    //create a callback
    U4DEngine::U4DCallback<GameController>* joystickCallback=new U4DEngine::U4DCallback<GameController>;
    
    joystickCallback->scheduleClassWithMethod(this, &GameController::actionOnJoystick);
    
    joyStick->setCallbackAction(joystickCallback);
    
    
    myButtonA=new U4DEngine::U4DButton("buttonA",0.3,-0.6,103,103,"ButtonA.png","ButtonAPressed.png");
    
    myButtonA->setControllerInterface(this);
    
    earth->addChild(myButtonA,-3);
    
    //create a callback
    U4DEngine::U4DCallback<GameController>* buttonACallback=new U4DEngine::U4DCallback<GameController>;
    
    buttonACallback->scheduleClassWithMethod(this, &GameController::actionOnButtonA);
    
    myButtonA->setCallbackAction(buttonACallback);
    
    
    myButtonB=new U4DEngine::U4DButton("buttonB",0.7,-0.6,103,103,"ButtonB.png","ButtonBPressed.png");
    
    myButtonB->setControllerInterface(this);
    
    earth->addChild(myButtonB,-4);
    
    //create a callback
    U4DEngine::U4DCallback<GameController>* buttonBCallback=new U4DEngine::U4DCallback<GameController>;
    
    buttonBCallback->scheduleClassWithMethod(this, &GameController::actionOnButtonB);
    
    myButtonB->setCallbackAction(buttonBCallback);
    
    // Create interactive objects for verb coin demo
    setupInteractiveObjects();
    
}

void GameController::setupInteractiveObjects(){
    
    Earth *earth=dynamic_cast<Earth*>(getGameWorld());
    
    // Create interactive chest
    interactiveChest = new U4DInteractiveEntity();
    interactiveChest->setEntityName("treasure_chest");
    interactiveChest->setDescription("A mysterious treasure chest");
    interactiveChest->setTexture("chest.png");
    interactiveChest->translateTo(-0.3f, 0.2f, 0.0f);
    
    // Add verbs to chest
    U4DEngine::U4DCallback<GameController>* examineChestCallback = new U4DEngine::U4DCallback<GameController>;
    examineChestCallback->scheduleClassWithMethod(this, &GameController::examineChest);
    interactiveChest->addDefaultExamineVerb(examineChestCallback);
    
    U4DEngine::U4DCallback<GameController>* openChestCallback = new U4DEngine::U4DCallback<GameController>;
    openChestCallback->scheduleClassWithMethod(this, &GameController::openChest);
    interactiveChest->addDefaultUseVerb(openChestCallback);
    
    U4DEngine::U4DCallback<GameController>* pickUpCallback = new U4DEngine::U4DCallback<GameController>;
    pickUpCallback->scheduleClassWithMethod(this, &GameController::pickUpFromChest);
    interactiveChest->addDefaultPickUpVerb(pickUpCallback);
    
    earth->addChild(interactiveChest, -5);
    
    // Create interactive door
    interactiveDoor = new U4DInteractiveEntity();
    interactiveDoor->setEntityName("wooden_door");
    interactiveDoor->setDescription("A heavy wooden door");
    interactiveDoor->setTexture("door.png");
    interactiveDoor->translateTo(0.3f, 0.2f, 0.0f);
    
    // Add verbs to door
    U4DEngine::U4DCallback<GameController>* examineDoorCallback = new U4DEngine::U4DCallback<GameController>;
    examineDoorCallback->scheduleClassWithMethod(this, &GameController::examineDoor);
    interactiveDoor->addDefaultExamineVerb(examineDoorCallback);
    
    U4DEngine::U4DCallback<GameController>* openDoorCallback = new U4DEngine::U4DCallback<GameController>;
    openDoorCallback->scheduleClassWithMethod(this, &GameController::openDoor);
    interactiveDoor->addDefaultUseVerb(openDoorCallback);
    
    earth->addChild(interactiveDoor, -6);
    
    // Create interactive character
    interactiveCharacter = new U4DInteractiveEntity();
    interactiveCharacter->setEntityName("village_npc");
    interactiveCharacter->setDescription("A friendly village NPC");
    interactiveCharacter->setTexture("character.png");
    interactiveCharacter->translateTo(0.0f, -0.2f, 0.0f);
    
    // Add verbs to character
    U4DEngine::U4DCallback<GameController>* examineCharacterCallback = new U4DEngine::U4DCallback<GameController>;
    examineCharacterCallback->scheduleClassWithMethod(this, &GameController::examineCharacter);
    interactiveCharacter->addDefaultExamineVerb(examineCharacterCallback);
    
    U4DEngine::U4DCallback<GameController>* talkCallback = new U4DEngine::U4DCallback<GameController>;
    talkCallback->scheduleClassWithMethod(this, &GameController::talkToCharacter);
    interactiveCharacter->addDefaultTalkVerb(talkCallback);
    
    earth->addChild(interactiveCharacter, -7);
    
}

void GameController::actionOnButtonA(){
    
    ControllerInputMessage controllerInputMessage;
    
    controllerInputMessage.controllerInputType=actionButtonA;
    
    if (myButtonA->getIsPressed()) {
        
        controllerInputMessage.controllerInputData=buttonPressed;
        
    }else if(myButtonA->getIsReleased()){
        
        controllerInputMessage.controllerInputData=buttonReleased;
        
    }
    
    sendUserInputUpdate(&controllerInputMessage);
}

void GameController::actionOnButtonB(){
    
    ControllerInputMessage controllerInputMessage;
    
    controllerInputMessage.controllerInputType=actionButtonB;
    
    if (myButtonB->getIsPressed()) {
        
        controllerInputMessage.controllerInputData=buttonPressed;
        
    }else if(myButtonB->getIsReleased()){
        
        controllerInputMessage.controllerInputData=buttonReleased;
        
    }
    
    sendUserInputUpdate(&controllerInputMessage);
}

void GameController::actionOnJoystick(){
    
    ControllerInputMessage controllerInputMessage;
    
    controllerInputMessage.controllerInputType=actionJoystick;
    
    if (joyStick->getIsActive()) {
        
        controllerInputMessage.controllerInputData=joystickActive;
        
        U4DEngine::U4DVector3n joystickDirection=joyStick->getDataPosition();
        
        joystickDirection.z=joystickDirection.y;
        
        joystickDirection.y=0;
        
        joystickDirection.normalize();
    
        
        if (joyStick->getDirectionReversal()) {
            
            controllerInputMessage.joystickChangeDirection=true;
            
        }else{
            
            controllerInputMessage.joystickChangeDirection=false;
            
        }
        
        controllerInputMessage.joystickDirection=joystickDirection;
        
    }else {
        
        controllerInputMessage.controllerInputData=joystickInactive;
        
    }
    
    sendUserInputUpdate(&controllerInputMessage);
}

// Verb action implementations
void GameController::examineChest() {
    // In a real game, this would show descriptive text or dialogue
    // For now, we'll just send a message indicating the action
    ControllerInputMessage message;
    message.controllerInputType = actionButtonA;
    message.controllerInputData = buttonPressed;
    sendUserInputUpdate(&message);
    // Could add: Display "The chest looks ancient and mysterious..."
}

void GameController::openChest() {
    // Open animation, reveal contents, etc.
    ControllerInputMessage message;
    message.controllerInputType = actionButtonB;
    message.controllerInputData = buttonPressed;
    sendUserInputUpdate(&message);
    // Could add: Play opening animation, show inventory items
}

void GameController::pickUpFromChest() {
    // Add items to inventory
    ControllerInputMessage message;
    message.controllerInputType = actionJoystick;
    message.controllerInputData = joystickActive;
    sendUserInputUpdate(&message);
    // Could add: Transfer items to player inventory
}

void GameController::examineDoor() {
    // Show door description
    ControllerInputMessage message;
    message.controllerInputType = actionButtonA;
    message.controllerInputData = buttonPressed;
    sendUserInputUpdate(&message);
    // Could add: Display "A sturdy wooden door with iron hinges..."
}

void GameController::openDoor() {
    // Try to open the door
    ControllerInputMessage message;
    message.controllerInputType = actionButtonB;
    message.controllerInputData = buttonPressed;
    sendUserInputUpdate(&message);
    // Could add: Check for key, play animation, load new scene
}

void GameController::examineCharacter() {
    // Show character description
    ControllerInputMessage message;
    message.controllerInputType = actionButtonA;
    message.controllerInputData = buttonPressed;
    sendUserInputUpdate(&message);
    // Could add: Display "A friendly villager with a warm smile..."
}

void GameController::talkToCharacter() {
    // Start dialogue
    ControllerInputMessage message;
    message.controllerInputType = actionButtonB;
    message.controllerInputData = buttonPressed;
    sendUserInputUpdate(&message);
    // Could add: Show dialogue tree, start conversation system
}

