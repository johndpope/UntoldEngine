//
//  U4DVerbIcon.mm
//  UntoldEngine
//
//  Created by Untold Engine Team on 7/22/25.
//  Copyright © 2025 Untold Engine. All rights reserved.
//

#include "U4DVerbIcon.h"
#include "U4DText.h"
#include "U4DDirector.h"
#include <cmath>

U4DVerbIcon::U4DVerbIcon() :
    iconState(eVerbIconIdle),
    tooltipLabel(nullptr),
    actionCallback(nullptr),
    hoverScale(1.2f),
    normalScale(1.0f),
    animationTimer(0.0f),
    showTooltip(false) {
    
    tooltipLabel = new U4DText();
    addChild(tooltipLabel);
}

U4DVerbIcon::~U4DVerbIcon() {
    if (tooltipLabel != nullptr) {
        removeChild(tooltipLabel);
        delete tooltipLabel;
        tooltipLabel = nullptr;
    }
    
    if (actionCallback != nullptr) {
        delete actionCallback;
        actionCallback = nullptr;
    }
}

void U4DVerbIcon::update(double dt) {
    
    animationTimer += dt;
    
    switch (iconState) {
        case eVerbIconHovered: {
            float targetScale = hoverScale;
            float currentScale = getLocalScale().x;
            float lerpFactor = 5.0f * dt; // Animation speed
            float newScale = currentScale + (targetScale - currentScale) * lerpFactor;
            
            U4DVector3n scaleVector(newScale, newScale, 1.0f);
            scaleTo(scaleVector);
            
            if (tooltipLabel != nullptr && showTooltip) {
                tooltipLabel->setVisibility(true);
            }
            break;
        }
        
        case eVerbIconIdle: {
            float targetScale = normalScale;
            float currentScale = getLocalScale().x;
            float lerpFactor = 5.0f * dt;
            float newScale = currentScale + (targetScale - currentScale) * lerpFactor;
            
            U4DVector3n scaleVector(newScale, newScale, 1.0f);
            scaleTo(scaleVector);
            
            if (tooltipLabel != nullptr) {
                tooltipLabel->setVisibility(false);
            }
            showTooltip = false;
            break;
        }
        
        case eVerbIconPressed: {
            float pressedScale = normalScale * 0.9f;
            U4DVector3n scaleVector(pressedScale, pressedScale, 1.0f);
            scaleTo(scaleVector);
            break;
        }
        
        default:
            break;
    }
}

void U4DVerbIcon::setVerbInfo(const std::string& name, const std::string& tooltip) {
    verbName = name;
    tooltipText = tooltip;
    
    if (tooltipLabel != nullptr) {
        tooltipLabel->setText(tooltipText);
        
        U4DVector3n tooltipPosition(0.0f, 0.15f, 0.0f); // Above icon
        tooltipLabel->translateTo(tooltipPosition);
        tooltipLabel->setVisibility(false);
    }
}

void U4DVerbIcon::setTexture(const std::string& textureName) {
    loadTexture(textureName.c_str());
}

void U4DVerbIcon::setCallback(U4DCallbackInterface *callback) {
    actionCallback = callback;
}

void U4DVerbIcon::setHovered(bool hovered) {
    if (hovered) {
        iconState = eVerbIconHovered;
    } else {
        iconState = eVerbIconIdle;
    }
}

bool U4DVerbIcon::isHovered() {
    return iconState == eVerbIconHovered;
}

void U4DVerbIcon::setPressed(bool pressed) {
    if (pressed) {
        iconState = eVerbIconPressed;
    } else {
        iconState = eVerbIconIdle;
    }
}

bool U4DVerbIcon::isPressed() {
    return iconState == eVerbIconPressed;
}

void U4DVerbIcon::executeAction() {
    if (actionCallback != nullptr) {
        actionCallback->action();
    }
}

void U4DVerbIcon::setTooltipVisible(bool visible) {
    showTooltip = visible;
    if (tooltipLabel != nullptr) {
        tooltipLabel->setVisibility(visible);
    }
}

bool U4DVerbIcon::isTooltipVisible() {
    return showTooltip;
}

void U4DVerbIcon::setHoverScale(float scale) {
    hoverScale = std::max(0.5f, scale);
}

float U4DVerbIcon::getHoverScale() {
    return hoverScale;
}

void U4DVerbIcon::setNormalScale(float scale) {
    normalScale = std::max(0.1f, scale);
}

float U4DVerbIcon::getNormalScale() {
    return normalScale;
}

bool U4DVerbIcon::isPointInside(U4DVector2n& point) {
    U4DDirector* director = U4DDirector::sharedInstance();
    U4DVector3n worldPos = getAbsolutePosition();
    
    float iconSize = 64.0f; // Assume 64x64 pixel icons
    float halfSize = iconSize / 2.0f;
    
    float screenX = worldPos.x * director->getDisplayWidth();
    float screenY = worldPos.y * director->getDisplayHeight();
    
    float touchX = point.x * director->getDisplayWidth();
    float touchY = point.y * director->getDisplayHeight();
    
    return (touchX >= screenX - halfSize && touchX <= screenX + halfSize &&
            touchY >= screenY - halfSize && touchY <= screenY + halfSize);
}

std::string U4DVerbIcon::getVerbName() {
    return verbName;
}

std::string U4DVerbIcon::getTooltipText() {
    return tooltipText;
}

void U4DVerbIcon::setState(VERBICONSTATES state) {
    iconState = state;
}

VERBICONSTATES U4DVerbIcon::getState() {
    return iconState;
}

void U4DVerbIcon::animateIn() {
    animationTimer = 0.0f;
    
    U4DVector3n startScale(0.1f, 0.1f, 1.0f);
    scaleTo(startScale);
    
    setVisibility(true);
}

void U4DVerbIcon::animateOut() {
    setVisibility(false);
}