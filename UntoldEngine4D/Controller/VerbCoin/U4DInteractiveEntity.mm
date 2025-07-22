//
//  U4DInteractiveEntity.mm
//  UntoldEngine
//
//  Created by Untold Engine Team on 7/22/25.
//  Copyright © 2025 Untold Engine. All rights reserved.
//

#include "U4DInteractiveEntity.h"
#include "U4DVerbCoinManager.h"
#import <Foundation/Foundation.h>

using namespace U4DEngine;

U4DInteractiveEntity::U4DInteractiveEntity() :
    isInteractable(true),
    showVerbCoinOnTouch(true),
    defaultActionCallback(nullptr) {
    
}

U4DInteractiveEntity::~U4DInteractiveEntity() {
    U4DVerbCoinManager* manager = U4DVerbCoinManager::sharedInstance();
    manager->unregisterEntity(this);
    
    for (auto& verb : availableVerbs) {
        if (verb.callback != nullptr) {
            delete verb.callback;
        }
    }
    availableVerbs.clear();
    
    if (defaultActionCallback != nullptr) {
        delete defaultActionCallback;
        defaultActionCallback = nullptr;
    }
}

void U4DInteractiveEntity::addVerb(VERBTYPE type, const std::string& iconTexture, const std::string& tooltipText, U4DCallbackInterface *callback) {
    
    for (auto& verb : availableVerbs) {
        if (verb.type == type) {
            if (verb.callback != nullptr) {
                delete verb.callback;
            }
            verb.iconTexture = iconTexture;
            verb.tooltipText = tooltipText;
            verb.callback = callback;
            return;
        }
    }
    
    VerbData newVerb(type, iconTexture, tooltipText, callback);
    availableVerbs.push_back(newVerb);
    
    U4DVerbCoinManager* manager = U4DVerbCoinManager::sharedInstance();
    manager->registerEntityVerbs(this, availableVerbs);
}

void U4DInteractiveEntity::removeVerb(VERBTYPE type) {
    for (auto it = availableVerbs.begin(); it != availableVerbs.end(); ++it) {
        if (it->type == type) {
            if (it->callback != nullptr) {
                delete it->callback;
            }
            availableVerbs.erase(it);
            break;
        }
    }
    
    U4DVerbCoinManager* manager = U4DVerbCoinManager::sharedInstance();
    manager->registerEntityVerbs(this, availableVerbs);
}

void U4DInteractiveEntity::clearAllVerbs() {
    for (auto& verb : availableVerbs) {
        if (verb.callback != nullptr) {
            delete verb.callback;
        }
    }
    availableVerbs.clear();
    
    U4DVerbCoinManager* manager = U4DVerbCoinManager::sharedInstance();
    manager->unregisterEntity(this);
}

std::vector<VerbData>& U4DInteractiveEntity::getAvailableVerbs() {
    return availableVerbs;
}

void U4DInteractiveEntity::setInteractable(bool interactable) {
    isInteractable = interactable;
}

bool U4DInteractiveEntity::getInteractable() {
    return isInteractable;
}

void U4DInteractiveEntity::setShowVerbCoinOnTouch(bool show) {
    showVerbCoinOnTouch = show;
}

bool U4DInteractiveEntity::getShowVerbCoinOnTouch() {
    return showVerbCoinOnTouch;
}

void U4DInteractiveEntity::setEntityName(const std::string& name) {
    entityName = name;
}

std::string U4DInteractiveEntity::getEntityName() {
    return entityName;
}

void U4DInteractiveEntity::setDescription(const std::string& desc) {
    description = desc;
}

std::string U4DInteractiveEntity::getDescription() {
    return description;
}

void U4DInteractiveEntity::setDefaultActionCallback(U4DCallbackInterface *callback) {
    if (defaultActionCallback != nullptr) {
        delete defaultActionCallback;
    }
    defaultActionCallback = callback;
}

U4DCallbackInterface* U4DInteractiveEntity::getDefaultActionCallback() {
    return defaultActionCallback;
}

void U4DInteractiveEntity::onTouch(U4DVector2n touchPosition) {
    if (!isInteractable) return;
    
    U4DVerbCoinManager* manager = U4DVerbCoinManager::sharedInstance();
    
    if (showVerbCoinOnTouch && !availableVerbs.empty()) {
        manager->showVerbCoinAtPosition(touchPosition, this);
    } else {
        executeDefaultAction();
    }
}

void U4DInteractiveEntity::executeDefaultAction() {
    if (defaultActionCallback != nullptr) {
        defaultActionCallback->action();
    } else if (!availableVerbs.empty()) {
        if (availableVerbs[0].callback != nullptr) {
            availableVerbs[0].callback->action();
        }
    }
}

bool U4DInteractiveEntity::hasVerb(VERBTYPE type) {
    for (const auto& verb : availableVerbs) {
        if (verb.type == type) {
            return true;
        }
    }
    return false;
}

VerbData* U4DInteractiveEntity::getVerb(VERBTYPE type) {
    for (auto& verb : availableVerbs) {
        if (verb.type == type) {
            return &verb;
        }
    }
    return nullptr;
}

void U4DInteractiveEntity::addDefaultExamineVerb(U4DCallbackInterface *callback) {
    addVerb(eVerbExamine, "eye_icon.png", "Look at", callback);
}

void U4DInteractiveEntity::addDefaultUseVerb(U4DCallbackInterface *callback) {
    addVerb(eVerbUse, "hand_icon.png", "Use", callback);
}

void U4DInteractiveEntity::addDefaultTalkVerb(U4DCallbackInterface *callback) {
    addVerb(eVerbTalk, "mouth_icon.png", "Talk to", callback);
}

void U4DInteractiveEntity::addDefaultPickUpVerb(U4DCallbackInterface *callback) {
    addVerb(eVerbPickUp, "pickup_icon.png", "Pick up", callback);
}

void U4DInteractiveEntity::setTexture(const std::string& textureName) {
    std::string actualTextureName = textureName;
    
    // Check if the requested texture file exists in the Resources directory
    std::string resourcePath = std::string([[NSBundle mainBundle].resourcePath UTF8String]) + "/" + textureName;
    NSString *nsResourcePath = [NSString stringWithUTF8String:resourcePath.c_str()];
    
    // If the file doesn't exist, use placeholder.png as fallback  
    if (![[NSFileManager defaultManager] fileExistsAtPath:nsResourcePath]) {
        actualTextureName = "placeholder.png";
        NSLog(@"Warning: Texture file '%s' not found. Using placeholder.png instead.", textureName.c_str());
    }
    
    // Set the diffuse texture for the interactive entity
    textureInformation.setDiffuseTexture(actualTextureName.c_str());
    setHasTexture(true);
    
    // Load the rendering information to apply the texture
    loadRenderingInformation();
}