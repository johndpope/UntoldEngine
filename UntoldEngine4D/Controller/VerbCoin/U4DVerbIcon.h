//
//  U4DVerbIcon.h
//  UntoldEngine
//
//  Created by Untold Engine Team on 7/22/25.
//  Copyright © 2025 Untold Engine. All rights reserved.
//

#ifndef U4DVerbIcon_h
#define U4DVerbIcon_h

#include <stdio.h>
#include "U4DImage.h"
#include "U4DVector2n.h"
#include "U4DCallbackInterface.h"
#include <string>

class U4DText;

typedef enum{
    eVerbIconIdle,
    eVerbIconHovered,
    eVerbIconPressed,
    eVerbIconSelected
} VERBICONSTATES;

class U4DVerbIcon : public U4DImage {
    
private:
    
    VERBICONSTATES iconState;
    
    std::string verbName;
    std::string tooltipText;
    U4DText *tooltipLabel;
    
    U4DCallbackInterface *actionCallback;
    
    float hoverScale;
    float normalScale;
    float animationTimer;
    
    bool showTooltip;
    
public:
    
    U4DVerbIcon();
    
    ~U4DVerbIcon();
    
    void update(double dt);
    
    void setVerbInfo(const std::string& name, const std::string& tooltip);
    
    void setTexture(const std::string& textureName);
    
    void setCallback(U4DCallbackInterface *callback);
    
    void setHovered(bool hovered);
    bool isHovered();
    
    void setPressed(bool pressed);
    bool isPressed();
    
    void executeAction();
    
    void setTooltipVisible(bool visible);
    bool isTooltipVisible();
    
    void setHoverScale(float scale);
    float getHoverScale();
    
    void setNormalScale(float scale);
    float getNormalScale();
    
    bool isPointInside(U4DVector2n& point);
    
    std::string getVerbName();
    std::string getTooltipText();
    
    void setState(VERBICONSTATES state);
    VERBICONSTATES getState();
    
    void animateIn();
    void animateOut();
    
};

#endif /* U4DVerbIcon_h */