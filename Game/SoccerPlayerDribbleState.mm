//
//  SoccerPlayerDribbleState.cpp
//  UntoldEngine
//
//  Created by Harold Serrano on 2/17/17.
//  Copyright © 2017 Untold Game Studio. All rights reserved.
//

#include "SoccerPlayerDribbleState.h"
#include "SoccerPlayerChaseBallState.h"
#include "SoccerPlayerGroundPassState.h"
#include "SoccerBall.h"

SoccerPlayerDribbleState* SoccerPlayerDribbleState::instance=0;

SoccerPlayerDribbleState::SoccerPlayerDribbleState(){
    
}

SoccerPlayerDribbleState::~SoccerPlayerDribbleState(){
    
}

SoccerPlayerDribbleState* SoccerPlayerDribbleState::sharedInstance(){
    
    if (instance==0) {
        instance=new SoccerPlayerDribbleState();
    }
    
    return instance;
    
}

void SoccerPlayerDribbleState::enter(SoccerPlayer *uPlayer){
    
    //set dribble animation
    uPlayer->setNextAnimationToPlay(uPlayer->getRunningAnimation());
    uPlayer->setPlayNextAnimationContinuously(true);
    uPlayer->setPlayBlendedAnimation(true);
    
    //set the initial angle for the foot swing
    uPlayer->setFootSwingInitAngle(90.0);
    
}

void SoccerPlayerDribbleState::execute(SoccerPlayer *uPlayer, double dt){
    
    float distanceToBall=uPlayer->distanceToBall();
    SoccerBall *ball=uPlayer->getBallEntity();
    
    //check if player should pass
    if (uPlayer->getButtonAPressed()) {
        
        uPlayer->setFlagToPassBall(true);
        
    }
    
    U4DEngine::U4DVector3n directionToKick=uPlayer->getPlayerHeading();
    
    //if the joystick is active, set the new direction of the kick
    if (uPlayer->getJoystickActive()) {
        
        directionToKick=uPlayer->getJoystickDirection();
        directionToKick.z=-directionToKick.y;
        
        directionToKick.y=0;
    }
    
    //dribble
    
    uPlayer->swingFeet(50.0,3.0,dt);
    
    //check if player should pass
    if (uPlayer->getFlagToPassBall()) {
        
        //ball->removeKineticForces();
        
        SoccerPlayerGroundPassState *groundPassState=SoccerPlayerGroundPassState::sharedInstance();
        
        uPlayer->changeState(groundPassState);
        
    }
    
    //keep dribbling
    if (!uPlayer->getFlagToPassBall()&&uPlayer->getFootCollidedWithBall()) {
        
        uPlayer->kickBallToGround(15.0, directionToKick,dt);
    
    }
    
    //check the distance between the ball and the player
    if (distanceToBall>5.0) {
        
        ball->removeKineticForces();
    }
    
    //chase the ball
    uPlayer->applyForceToPlayer(10.0, dt);
    
    uPlayer->trackBall();
}

void SoccerPlayerDribbleState::exit(SoccerPlayer *uPlayer){
    
}
