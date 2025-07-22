//
//  U4DVerbCoinManager.mm
//  UntoldEngine
//
//  Created by Untold Engine Team on 7/22/25.
//  Copyright © 2025 Untold Engine. All rights reserved.
//

#include "U4DVerbCoinManager.h"
#include "U4DVerbCoin.h"
#include "U4DInteractiveEntity.h"
#include "U4DTouches.h"
#include "U4DDirector.h"
#include "U4DWorld.h"
#include <cmath>

U4DVerbCoinManager* U4DVerbCoinManager::instance = nullptr;

U4DVerbCoinManager* U4DVerbCoinManager::sharedInstance() {
    if (instance == nullptr) {
        instance = new U4DVerbCoinManager();
    }
    return instance;
}

U4DVerbCoinManager::U4DVerbCoinManager() :
    activeVerbCoin(nullptr),
    longPressDuration(0.5f),
    currentPressTime(0.0f),
    isLongPressing(false),
    globalVerbCallback(nullptr) {
    
    activeVerbCoin = new U4DVerbCoin();
}

U4DVerbCoinManager::~U4DVerbCoinManager() {
    if (activeVerbCoin != nullptr) {
        delete activeVerbCoin;
        activeVerbCoin = nullptr;
    }
    
    entityVerbMap.clear();
    
    if (globalVerbCallback != nullptr) {
        delete globalVerbCallback;
        globalVerbCallback = nullptr;
    }
}

void U4DVerbCoinManager::update(double dt) {
    if (activeVerbCoin != nullptr) {
        activeVerbCoin->update(dt);
    }
    
    if (isLongPressing) {
        currentPressTime += dt;
        if (currentPressTime >= longPressDuration) {
            showVerbCoinAtPosition(pressStartPosition);
            isLongPressing = false;
            currentPressTime = 0.0f;
        }
    }
}

void U4DVerbCoinManager::showVerbCoinAtPosition(U4DVector2n position, U4DEntity* targetEntity) {
    if (activeVerbCoin == nullptr) return;
    
    std::vector<VerbData> verbs;
    
    if (targetEntity != nullptr) {
        auto it = entityVerbMap.find(targetEntity);
        if (it != entityVerbMap.end()) {
            verbs = it->second;
        } else {
            addDefaultVerbs(targetEntity);
            verbs = entityVerbMap[targetEntity];
        }
    } else {
        VerbData examineVerb(eVerbExamine, "eye_icon.png", "Look at", nullptr);
        verbs.push_back(examineVerb);
    }
    
    if (!verbs.empty()) {
        activeVerbCoin->showVerbCoin(position, verbs);
    }
}

void U4DVerbCoinManager::hideVerbCoin() {
    if (activeVerbCoin != nullptr) {
        activeVerbCoin->hideVerbCoin();
    }
}

bool U4DVerbCoinManager::isVerbCoinVisible() {
    if (activeVerbCoin != nullptr) {
        return activeVerbCoin->isVisible();
    }
    return false;
}

void U4DVerbCoinManager::registerEntityVerbs(U4DEntity* entity, std::vector<VerbData>& verbs) {
    if (entity != nullptr) {
        entityVerbMap[entity] = verbs;
    }
}

void U4DVerbCoinManager::unregisterEntity(U4DEntity* entity) {
    auto it = entityVerbMap.find(entity);
    if (it != entityVerbMap.end()) {
        entityVerbMap.erase(it);
    }
}

void U4DVerbCoinManager::setLongPressDuration(float duration) {
    longPressDuration = std::max(0.1f, duration);
}

float U4DVerbCoinManager::getLongPressDuration() {
    return longPressDuration;
}

void U4DVerbCoinManager::setGlobalVerbCallback(U4DCallbackInterface *callback) {
    globalVerbCallback = callback;
}

void U4DVerbCoinManager::touchBegan(U4DTouches *touches) {
    if (touches == nullptr) return;
    
    U4DVector2n touchPosition(touches->x, touches->y);
    
    if (isVerbCoinVisible()) {
        activeVerbCoin->touchBegan(touches);
        return;
    }
    
    isLongPressing = true;
    currentPressTime = 0.0f;
    pressStartPosition = touchPosition;
}

void U4DVerbCoinManager::touchMoved(U4DTouches *touches) {
    if (touches == nullptr) return;
    
    if (isVerbCoinVisible()) {
        activeVerbCoin->touchMoved(touches);
        return;
    }
    
    U4DVector2n currentPosition(touches->x, touches->y);
    float distance = sqrt(pow(currentPosition.x - pressStartPosition.x, 2) + 
                         pow(currentPosition.y - pressStartPosition.y, 2));
    
    if (distance > 0.05f) {
        isLongPressing = false;
        currentPressTime = 0.0f;
    }
}

void U4DVerbCoinManager::touchEnded(U4DTouches *touches) {
    if (touches == nullptr) return;
    
    if (isVerbCoinVisible()) {
        activeVerbCoin->touchEnded(touches);
        return;
    }
    
    isLongPressing = false;
    currentPressTime = 0.0f;
    
    U4DVector2n touchPosition(touches->x, touches->y);
    U4DEntity* entityAtPosition = getEntityAtPosition(touchPosition);
    
    if (entityAtPosition != nullptr) {
        U4DInteractiveEntity* interactiveEntity = dynamic_cast<U4DInteractiveEntity*>(entityAtPosition);
        if (interactiveEntity != nullptr && interactiveEntity->getInteractable()) {
            if (interactiveEntity->getShowVerbCoinOnTouch()) {
                showVerbCoinAtPosition(touchPosition, entityAtPosition);
            } else {
                interactiveEntity->executeDefaultAction();
            }
        }
    }
}

U4DEntity* U4DVerbCoinManager::getEntityAtPosition(U4DVector2n position) {
    U4DDirector* director = U4DDirector::sharedInstance();
    U4DWorld* world = director->getWorld();
    
    if (world == nullptr) return nullptr;
    
    return world->searchChild("interactive");
}

void U4DVerbCoinManager::addDefaultVerbs(U4DEntity* entity) {
    if (entity == nullptr) return;
    
    std::vector<VerbData> defaultVerbs;
    
    VerbData examineVerb(eVerbExamine, "eye_icon.png", "Look at", nullptr);
    VerbData useVerb(eVerbUse, "hand_icon.png", "Use", nullptr);
    VerbData talkVerb(eVerbTalk, "mouth_icon.png", "Talk to", nullptr);
    
    defaultVerbs.push_back(examineVerb);
    defaultVerbs.push_back(useVerb);
    defaultVerbs.push_back(talkVerb);
    
    entityVerbMap[entity] = defaultVerbs;
}

void U4DVerbCoinManager::clearAllEntityVerbs() {
    entityVerbMap.clear();
}

U4DVerbCoin* U4DVerbCoinManager::getActiveVerbCoin() {
    return activeVerbCoin;
}