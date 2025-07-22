//
//  U4DVerbIcon.mm
//  UntoldEngine
//
//  Created by Untold Engine Team on 7/22/25.
//  Copyright © 2025 Untold Engine. All rights reserved.
//

#include "U4DVerbIcon.h"
#include "../../Objects/Fonts/U4DText.h"
#include "../../Director/U4DDirector.h"
#include "../../FontAssetLoader/U4DFontLoader.h"
#include <cmath>

using namespace U4DEngine;

U4DVerbIcon::U4DVerbIcon() :
    iconState(eVerbIconIdle),
    tooltipLabel(nullptr),
    fontLoader(nullptr),
    actionCallback(nullptr),
    hoverScale(1.2f),
    normalScale(1.0f),
    animationTimer(0.0f),
    showTooltip(false) {
    
    // For now, don't create tooltip text to avoid font loading complexity
    // tooltipLabel will be created when setVerbInfo is called with proper font setup
    tooltipLabel = nullptr;
}

U4DVerbIcon::~U4DVerbIcon() {
    if (tooltipLabel != nullptr) {
        removeChild(tooltipLabel);
        delete tooltipLabel;
        tooltipLabel = nullptr;
    }
    
    if (fontLoader != nullptr) {
        delete fontLoader;
        fontLoader = nullptr;
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
            float currentScale = normalScale; // Start from normal scale
            float lerpFactor = 5.0f * dt; // Animation speed
            float newScale = currentScale + (targetScale - currentScale) * lerpFactor;
            
            // Use setImageDimension for scaling effect
            float baseWidth = 64.0f; // Base icon size
            float baseHeight = 64.0f;
            setImageDimension(baseWidth * newScale, baseHeight * newScale);
            
            if (tooltipLabel != nullptr && showTooltip) {
                // Add tooltip to scene graph to make it visible
                if (tooltipLabel->getParent() == nullptr) {
                    addChild(static_cast<U4DEntity*>(tooltipLabel));
                }
            }
            break;
        }
        
        case eVerbIconIdle: {
            float targetScale = normalScale;
            float currentScale = normalScale; // Assume at normal scale
            float lerpFactor = 5.0f * dt;
            float newScale = currentScale + (targetScale - currentScale) * lerpFactor;
            
            // Use setImageDimension for scaling effect
            float baseWidth = 64.0f; // Base icon size
            float baseHeight = 64.0f;
            setImageDimension(baseWidth * newScale, baseHeight * newScale);
            
            if (tooltipLabel != nullptr) {
                // Remove tooltip from scene graph to hide it
                if (tooltipLabel->getParent() != nullptr) {
                    removeChild(tooltipLabel);
                }
            }
            showTooltip = false;
            break;
        }
        
        case eVerbIconPressed: {
            float pressedScale = normalScale * 0.9f;
            // Use setImageDimension for scaling effect
            float baseWidth = 64.0f; // Base icon size
            float baseHeight = 64.0f;
            setImageDimension(baseWidth * pressedScale, baseHeight * pressedScale);
            break;
        }
        
        default:
            break;
    }
}

void U4DVerbIcon::setVerbInfo(const std::string& name, const std::string& tooltip) {
    verbName = name;
    tooltipText = tooltip;
    
    // Create tooltip text if not already created and tooltip text is provided
    if (tooltipLabel == nullptr && !tooltip.empty()) {
        fontLoader = new U4DFontLoader();
        tooltipLabel = new U4DText(fontLoader, 1.0f);
        addChild(static_cast<U4DEntity*>(tooltipLabel));
    }
    
    if (tooltipLabel != nullptr) {
        tooltipLabel->setText(tooltipText.c_str());
        
        U4DVector3n tooltipPosition(0.0f, 0.15f, 0.0f); // Above icon
        tooltipLabel->translateTo(tooltipPosition);
        // Remove tooltip from scene graph initially (hidden)
        if (tooltipLabel->getParent() != nullptr) {
            removeChild(tooltipLabel);
        }
    }
}

void U4DVerbIcon::setTexture(const std::string& textureName) {
    // Use setImage from U4DImage base class
    setImage(textureName.c_str(), 64.0f, 64.0f);
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
        if (visible) {
            // Add to scene graph to show
            if (tooltipLabel->getParent() == nullptr) {
                addChild(static_cast<U4DEntity*>(tooltipLabel));
            }
        } else {
            // Remove from scene graph to hide
            if (tooltipLabel->getParent() != nullptr) {
                removeChild(tooltipLabel);
            }
        }
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
    
    // Start with small size and make visible
    float baseWidth = 64.0f;
    float baseHeight = 64.0f;
    setImageDimension(baseWidth * 0.1f, baseHeight * 0.1f);
    
    // Icon is already visible through the scene graph - no action needed
    // Animation scaling will be handled by setImageDimension
}

void U4DVerbIcon::animateOut() {
    // Hide the icon by removing it from scene graph or moving it off-screen
    // For now, just move it off-screen
    U4DVector3n offScreen(-10000.0f, -10000.0f, 0.0f);
    translateTo(offScreen);
}