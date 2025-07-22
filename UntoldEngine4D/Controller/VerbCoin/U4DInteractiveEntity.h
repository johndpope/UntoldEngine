//
//  U4DInteractiveEntity.h
//  UntoldEngine
//
//  Created by Untold Engine Team on 7/22/25.
//  Copyright © 2025 Untold Engine. All rights reserved.
//

#ifndef U4DInteractiveEntity_h
#define U4DInteractiveEntity_h

#include <stdio.h>
#include "U4DVisibleEntity.h"
#include "U4DVector2n.h"
#include "U4DCallbackInterface.h"
#include <vector>
#include <string>

struct VerbData;

class U4DInteractiveEntity : public U4DVisibleEntity {
    
private:
    
    std::vector<VerbData> availableVerbs;
    std::string entityName;
    std::string description;
    
    bool isInteractable;
    bool showVerbCoinOnTouch;
    
    U4DCallbackInterface *defaultActionCallback;
    
public:
    
    U4DInteractiveEntity();
    
    ~U4DInteractiveEntity();
    
    void addVerb(VERBTYPE type, const std::string& iconTexture, const std::string& tooltipText, U4DCallbackInterface *callback);
    
    void removeVerb(VERBTYPE type);
    
    void clearAllVerbs();
    
    std::vector<VerbData>& getAvailableVerbs();
    
    void setInteractable(bool interactable);
    bool getInteractable();
    
    void setShowVerbCoinOnTouch(bool show);
    bool getShowVerbCoinOnTouch();
    
    void setEntityName(const std::string& name);
    std::string getEntityName();
    
    void setDescription(const std::string& desc);
    std::string getDescription();
    
    void setDefaultActionCallback(U4DCallbackInterface *callback);
    U4DCallbackInterface* getDefaultActionCallback();
    
    void onTouch(U4DVector2n touchPosition);
    
    void executeDefaultAction();
    
    bool hasVerb(VERBTYPE type);
    
    VerbData* getVerb(VERBTYPE type);
    
    void addDefaultExamineVerb(U4DCallbackInterface *callback);
    
    void addDefaultUseVerb(U4DCallbackInterface *callback);
    
    void addDefaultTalkVerb(U4DCallbackInterface *callback);
    
    void addDefaultPickUpVerb(U4DCallbackInterface *callback);
    
};

#endif /* U4DInteractiveEntity_h */