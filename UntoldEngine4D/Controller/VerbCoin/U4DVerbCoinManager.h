//
//  U4DVerbCoinManager.h
//  UntoldEngine
//
//  Created by Untold Engine Team on 7/22/25.
//  Copyright © 2025 Untold Engine. All rights reserved.
//

#ifndef U4DVerbCoinManager_h
#define U4DVerbCoinManager_h

#include <stdio.h>
#include "U4DVector2n.h"
#include "U4DCallbackInterface.h"
#include <vector>
#include <map>

class U4DVerbCoin;
class U4DEntity;
class U4DTouches;

struct VerbData;

typedef enum{
    eRightClick,
    eLongPress,
    eKeyPress
} VERBCOINTRIGGER;

class U4DVerbCoinManager {
    
private:
    
    static U4DVerbCoinManager* instance;
    
    U4DVerbCoin* activeVerbCoin;
    
    float longPressDuration;
    float currentPressTime;
    bool isLongPressing;
    U4DVector2n pressStartPosition;
    
    std::map<U4DEntity*, std::vector<VerbData>> entityVerbMap;
    
    U4DCallbackInterface *globalVerbCallback;
    
    U4DVerbCoinManager();
    
public:
    
    static U4DVerbCoinManager* sharedInstance();
    
    ~U4DVerbCoinManager();
    
    void update(double dt);
    
    void showVerbCoinAtPosition(U4DVector2n position, U4DEntity* targetEntity = nullptr);
    
    void hideVerbCoin();
    
    bool isVerbCoinVisible();
    
    void registerEntityVerbs(U4DEntity* entity, std::vector<VerbData>& verbs);
    
    void unregisterEntity(U4DEntity* entity);
    
    void setLongPressDuration(float duration);
    float getLongPressDuration();
    
    void setGlobalVerbCallback(U4DCallbackInterface *callback);
    
    void touchBegan(U4DTouches *touches);
    void touchMoved(U4DTouches *touches);
    void touchEnded(U4DTouches *touches);
    
    U4DEntity* getEntityAtPosition(U4DVector2n position);
    
    void addDefaultVerbs(U4DEntity* entity);
    
    void clearAllEntityVerbs();
    
    U4DVerbCoin* getActiveVerbCoin();
    
};

#endif /* U4DVerbCoinManager_h */