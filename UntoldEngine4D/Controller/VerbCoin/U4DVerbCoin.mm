//
//  U4DVerbCoin.mm
//  UntoldEngine
//
//  Created by Untold Engine Team on 7/22/25.
//  Copyright © 2025 Untold Engine. All rights reserved.
//

#include "U4DVerbCoin.h"
#include "U4DVerbIcon.h"
#include "../../Touches/U4DTouches.h"
#include "../../Director/U4DDirector.h"
#include <cmath>

using namespace U4DEngine;

U4DVerbCoin::U4DVerbCoin() :
    verbCoinState(eVerbCoinHidden),
    radius(100.0f),
    fadeTimer(0.0f),
    showDuration(3.0f),
    hoveredIcon(nullptr),
    onVerbSelected(nullptr) {
    
}

U4DVerbCoin::~U4DVerbCoin() {
    clearVerbs();
    
    if (onVerbSelected != nullptr) {
        delete onVerbSelected;
        onVerbSelected = nullptr;
    }
}

void U4DVerbCoin::update(double dt) {
    
    switch (verbCoinState) {
        case eVerbCoinShowing:
            fadeTimer += dt;
            if (fadeTimer >= showDuration) {
                hideVerbCoin();
            }
            break;
            
        case eVerbCoinHidden:
            break;
            
        case eVerbCoinHovering:
            break;
            
        default:
            break;
    }
    
    for (auto& icon : verbIcons) {
        if (icon != nullptr) {
            icon->update(dt);
        }
    }
}

void U4DVerbCoin::showVerbCoin(U4DVector2n position, std::vector<VerbData>& verbs) {
    
    if (verbs.empty()) return;
    
    centerPosition = position;
    availableVerbs = verbs;
    
    clearVerbs();
    
    for (size_t i = 0; i < verbs.size(); ++i) {
        U4DVerbIcon* icon = new U4DVerbIcon();
        icon->setTexture(verbs[i].iconTexture);
        icon->setVerbInfo(verbs[i].tooltipText, verbs[i].tooltipText);
        icon->setCallback(verbs[i].callback);
        
        verbIcons.push_back(icon);
        addChild(icon);
    }
    
    arrangeIconsRadially();
    
    verbCoinState = eVerbCoinShowing;
    fadeTimer = 0.0f;
    
    for (auto& icon : verbIcons) {
        if (icon != nullptr) {
            icon->animateIn();
        }
    }
}

void U4DVerbCoin::hideVerbCoin() {
    verbCoinState = eVerbCoinHidden;
    fadeTimer = 0.0f;
    hoveredIcon = nullptr;
    
    for (auto& icon : verbIcons) {
        if (icon != nullptr) {
            icon->animateOut();
        }
    }
}

bool U4DVerbCoin::isVisible() {
    return verbCoinState == eVerbCoinShowing || verbCoinState == eVerbCoinHovering;
}

void U4DVerbCoin::arrangeIconsRadially() {
    if (verbIcons.empty()) return;
    
    float angleStep = (2.0f * M_PI) / verbIcons.size();
    float startAngle = -M_PI / 2.0f; // Start at top
    
    U4DDirector* director = U4DDirector::sharedInstance();
    float screenWidth = director->getDisplayWidth();
    float screenHeight = director->getDisplayHeight();
    
    for (size_t i = 0; i < verbIcons.size(); ++i) {
        float angle = startAngle + (i * angleStep);
        
        float x = centerPosition.x + (radius * cos(angle)) / screenWidth;
        float y = centerPosition.y + (radius * sin(angle)) / screenHeight;
        
        U4DVector3n iconPosition(x, y, 0.0f);
        verbIcons[i]->translateTo(iconPosition);
    }
}

void U4DVerbCoin::updateIconPositions() {
    arrangeIconsRadially();
}

U4DVerbIcon* U4DVerbCoin::getIconAtPosition(U4DVector2n& position) {
    for (auto& icon : verbIcons) {
        if (icon != nullptr && icon->isPointInside(position)) {
            return icon;
        }
    }
    return nullptr;
}

void U4DVerbCoin::setRadius(float r) {
    radius = std::max(50.0f, r);
    updateIconPositions();
}

float U4DVerbCoin::getRadius() {
    return radius;
}

void U4DVerbCoin::setShowDuration(float duration) {
    showDuration = std::max(1.0f, duration);
}

float U4DVerbCoin::getShowDuration() {
    return showDuration;
}

void U4DVerbCoin::setCallback(U4DCallbackInterface *callback) {
    onVerbSelected = callback;
}

void U4DVerbCoin::touchBegan(U4DTouches *touches) {
    if (touches == nullptr || !isVisible()) return;
    
    U4DVector2n touchPosition(touches->xTouch, touches->yTouch);
    U4DVerbIcon* iconAtPosition = getIconAtPosition(touchPosition);
    
    if (iconAtPosition != nullptr) {
        iconAtPosition->setPressed(true);
        verbCoinState = eVerbCoinHovering;
        fadeTimer = 0.0f;
    } else {
        hideVerbCoin();
    }
}

void U4DVerbCoin::touchMoved(U4DTouches *touches) {
    if (touches == nullptr || !isVisible()) return;
    
    U4DVector2n touchPosition(touches->xTouch, touches->yTouch);
    U4DVerbIcon* iconAtPosition = getIconAtPosition(touchPosition);
    
    if (hoveredIcon != iconAtPosition) {
        if (hoveredIcon != nullptr) {
            hoveredIcon->setHovered(false);
            hoveredIcon->setPressed(false);
        }
        
        hoveredIcon = iconAtPosition;
        
        if (hoveredIcon != nullptr) {
            hoveredIcon->setHovered(true);
            hoveredIcon->setTooltipVisible(true);
        }
    }
}

void U4DVerbCoin::touchEnded(U4DTouches *touches) {
    if (touches == nullptr || !isVisible()) return;
    
    U4DVector2n touchPosition(touches->xTouch, touches->yTouch);
    U4DVerbIcon* iconAtPosition = getIconAtPosition(touchPosition);
    
    if (iconAtPosition != nullptr) {
        iconAtPosition->setPressed(false);
        iconAtPosition->executeAction();
        
        if (onVerbSelected != nullptr) {
            onVerbSelected->action();
        }
    }
    
    hideVerbCoin();
}

void U4DVerbCoin::addVerb(VERBTYPE type, const std::string& iconTexture, const std::string& tooltipText, U4DCallbackInterface *callback) {
    VerbData verb(type, iconTexture, tooltipText, callback);
    availableVerbs.push_back(verb);
}

void U4DVerbCoin::clearVerbs() {
    for (auto& icon : verbIcons) {
        if (icon != nullptr) {
            removeChild(icon);
            delete icon;
        }
    }
    verbIcons.clear();
    availableVerbs.clear();
    hoveredIcon = nullptr;
}

VERBTYPE U4DVerbCoin::getSelectedVerb() {
    if (hoveredIcon != nullptr) {
        for (size_t i = 0; i < verbIcons.size(); ++i) {
            if (verbIcons[i] == hoveredIcon) {
                return availableVerbs[i].type;
            }
        }
    }
    return eVerbExamine; // Default
}

void U4DVerbCoin::setState(VERBCOINSTATES state) {
    verbCoinState = state;
}

VERBCOINSTATES U4DVerbCoin::getState() {
    return verbCoinState;
}