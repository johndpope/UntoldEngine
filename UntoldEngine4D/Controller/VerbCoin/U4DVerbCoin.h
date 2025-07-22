//
//  U4DVerbCoin.h
//  UntoldEngine
//
//  Created by Untold Engine Team on 7/22/25.
//  Copyright © 2025 Untold Engine. All rights reserved.
//

#ifndef U4DVerbCoin_h
#define U4DVerbCoin_h

#include <stdio.h>
#include "U4DVisibleEntity.h"
#include "U4DVector2n.h"
#include "U4DCallbackInterface.h"
#include "U4DVector3n.h"
#include <vector>

class U4DVerbIcon;
class U4DTouches;

typedef enum{
    eVerbCoinIdle,
    eVerbCoinShowing,
    eVerbCoinHidden,
    eVerbCoinHovering
} VERBCOINSTATES;

typedef enum{
    eVerbExamine,
    eVerbUse,
    eVerbTalk,
    eVerbPickUp,
    eVerbCombine,
    eVerbCustom
} VERBTYPE;

struct VerbData {
    VERBTYPE type;
    std::string iconTexture;
    std::string tooltipText;
    U4DCallbackInterface *callback;
    
    VerbData(VERBTYPE t, const std::string& icon, const std::string& tooltip, U4DCallbackInterface *cb)
        : type(t), iconTexture(icon), tooltipText(tooltip), callback(cb) {}
};

class U4DVerbCoin : public U4DVisibleEntity {
    
private:
    
    VERBCOINSTATES verbCoinState;
    
    std::vector<U4DVerbIcon*> verbIcons;
    std::vector<VerbData> availableVerbs;
    
    U4DVector2n centerPosition;
    float radius;
    float fadeTimer;
    float showDuration;
    
    U4DVerbIcon* hoveredIcon;
    U4DCallbackInterface *onVerbSelected;
    
    void arrangeIconsRadially();
    void updateIconPositions();
    U4DVerbIcon* getIconAtPosition(U4DVector2n& position);
    
public:
    
    U4DVerbCoin();
    
    ~U4DVerbCoin();
    
    void update(double dt);
    
    void showVerbCoin(U4DVector2n position, std::vector<VerbData>& verbs);
    
    void hideVerbCoin();
    
    bool isVisible();
    
    void setRadius(float radius);
    float getRadius();
    
    void setShowDuration(float duration);
    float getShowDuration();
    
    void setCallback(U4DCallbackInterface *callback);
    
    void touchBegan(U4DTouches *touches);
    void touchMoved(U4DTouches *touches);
    void touchEnded(U4DTouches *touches);
    
    void addVerb(VERBTYPE type, const std::string& iconTexture, const std::string& tooltipText, U4DCallbackInterface *callback);
    
    void clearVerbs();
    
    VERBTYPE getSelectedVerb();
    
    void setState(VERBCOINSTATES state);
    VERBCOINSTATES getState();
    
};

#endif /* U4DVerbCoin_h */