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
#include "../../Objects/U4DVisibleEntity.h"
#include "../../MathematicEngine/U4DVector2n.h"
#include "../../Callback/U4DCallbackInterface.h"
#include "../../MathematicEngine/U4DVector3n.h"
#include <vector>

using namespace U4DEngine;

class U4DVerbIcon;

namespace U4DEngine {
    class U4DTouches;
}

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
    U4DEngine::U4DCallbackInterface *callback;
    
    VerbData(VERBTYPE t, const std::string& icon, const std::string& tooltip, U4DEngine::U4DCallbackInterface *cb)
        : type(t), iconTexture(icon), tooltipText(tooltip), callback(cb) {}
};

class U4DVerbCoin : public U4DEngine::U4DVisibleEntity {
    
private:
    
    VERBCOINSTATES verbCoinState;
    
    std::vector<U4DVerbIcon*> verbIcons;
    std::vector<VerbData> availableVerbs;
    
    U4DEngine::U4DVector2n centerPosition;
    float radius;
    float fadeTimer;
    float showDuration;
    
    U4DVerbIcon* hoveredIcon;
    U4DEngine::U4DCallbackInterface *onVerbSelected;
    
    void arrangeIconsRadially();
    void updateIconPositions();
    U4DVerbIcon* getIconAtPosition(U4DEngine::U4DVector2n& position);
    
public:
    
    U4DVerbCoin();
    
    ~U4DVerbCoin();
    
    void update(double dt);
    
    void showVerbCoin(U4DEngine::U4DVector2n position, std::vector<VerbData>& verbs);
    
    void hideVerbCoin();
    
    bool isVisible();
    
    void setRadius(float radius);
    float getRadius();
    
    void setShowDuration(float duration);
    float getShowDuration();
    
    void setCallback(U4DEngine::U4DCallbackInterface *callback);
    
    void touchBegan(U4DEngine::U4DTouches *touches);
    void touchMoved(U4DEngine::U4DTouches *touches);
    void touchEnded(U4DEngine::U4DTouches *touches);
    
    void addVerb(VERBTYPE type, const std::string& iconTexture, const std::string& tooltipText, U4DEngine::U4DCallbackInterface *callback);
    
    void clearVerbs();
    
    VERBTYPE getSelectedVerb();
    
    void setState(VERBCOINSTATES state);
    VERBCOINSTATES getState();
    
};

#endif /* U4DVerbCoin_h */