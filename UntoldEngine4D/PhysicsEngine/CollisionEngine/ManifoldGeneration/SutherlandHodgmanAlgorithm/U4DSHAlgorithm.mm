//
//  U4DSHAlgorithm.cpp
//  UntoldEngine
//
//  Created by Harold Serrano on 4/18/16.
//  Copyright © 2016 Untold Game Studio. All rights reserved.
//

#include "U4DSHAlgorithm.h"
#include "U4DPlane.h"
#include "U4DSegment.h"
#include "U4DTriangle.h"
#include "Constants.h"

namespace U4DEngine {

    U4DSHAlgorithm::U4DSHAlgorithm(){
        
    }
    
    U4DSHAlgorithm::~U4DSHAlgorithm(){
        
    }
    
    bool U4DSHAlgorithm::determineContactManifold(U4DDynamicModel* uModel1, U4DDynamicModel* uModel2,std::vector<U4DSimplexStruct> uQ,U4DPoint3n& uClosestPoint){
        
        //step 1. Create plane
        U4DVector3n collisionNormalOfModel1=uModel1->getCollisionNormalFaceDirection();
        U4DPlane planeCollisionOfModel1(collisionNormalOfModel1,uClosestPoint);
        
        U4DVector3n collisionNormalOfModel2=uModel2->getCollisionNormalFaceDirection();
        U4DPlane planeCollisionOfModel2(collisionNormalOfModel2,uClosestPoint);
        
        if (collisionNormalOfModel1==U4DVector3n(0,0,0) || collisionNormalOfModel2==U4DVector3n(0,0,0)) {
            return false;
        }
        
        //step 2. For each model determine which face is most parallel to plane, i.e., dot product ~0
        
        std::vector<CONTACTFACES> parallelFacesModel1=mostParallelFacesToPlane(uModel1, planeCollisionOfModel1);
        
        std::vector<CONTACTFACES> parallelFacesModel2=mostParallelFacesToPlane(uModel2, planeCollisionOfModel2);
        
        //step 3. for each model project selected faces onto plane
        
        std::vector<U4DTriangle> projectedFacesModel1=projectFacesToPlane(parallelFacesModel1, planeCollisionOfModel1);
        
        std::vector<U4DTriangle> projectedFacesModel2=projectFacesToPlane(parallelFacesModel2, planeCollisionOfModel2);
        
        //step 4. Break triangle into segments and remove any duplicate segments
        std::vector<CONTACTEDGE> polygonEdgesOfModel1=getEdgesFromFaces(projectedFacesModel1,planeCollisionOfModel1);
        std::vector<CONTACTEDGE> polygonEdgesOfModel2=getEdgesFromFaces(projectedFacesModel2,planeCollisionOfModel2);
        
        //step 5. Determine reference polygon

        float maxFaceParallelToPlaneInModel1=-FLT_MIN;
        float maxFaceParallelToPlaneInModel2=-FLT_MIN;
        
        //Get the most dot product parallel to plane for each model
        for(auto n:parallelFacesModel1){
            
            maxFaceParallelToPlaneInModel1=MAX(n.dotProduct,maxFaceParallelToPlaneInModel1);
            
        }
        
        for(auto n:parallelFacesModel2){
            
            maxFaceParallelToPlaneInModel2=MAX(n.dotProduct,maxFaceParallelToPlaneInModel2);
            
        }
        
        //compare dot product and assign a reference plane
        
        //step 5. perform sutherland
        
        std::vector<U4DSegment> segments;
        
        if (maxFaceParallelToPlaneInModel1>=maxFaceParallelToPlaneInModel2) {
            
            //set polygon in model 1 as the reference plane
            //and polygon in model 2 as the incident plane
            //project the closest point onto the plane
            
            segments=clipPolygons(polygonEdgesOfModel1, polygonEdgesOfModel2);
            uClosestPoint=planeCollisionOfModel1.closestPointToPlane(uClosestPoint);
            
        }else{
            
            //set polygon in model 2 as the reference plane
            //and polygon in model 1 as the incident plane
            //project the closest point onto the plane
            
            segments=clipPolygons(polygonEdgesOfModel2, polygonEdgesOfModel1);
            uClosestPoint=planeCollisionOfModel2.closestPointToPlane(uClosestPoint);
        }
        
        
        for(auto n: segments){
            
            float distance=n.sqDistancePointSegment(uClosestPoint);
            
            //check if segment is close to the closest point from GJK
            if (distance<U4DEngine::closestDistanceToSimplexEpsilon) {
                
                uModel1->clearCollisionContactPoints();
                uModel2->clearCollisionContactPoints();
            
                if (n.pointA.distanceSquareBetweenPoints(uClosestPoint)<U4DEngine::closestDistanceToSimplexEpsilon) {
                    //return one point as contact point
                    
                    U4DVector3n pointA=n.pointA.toVector();
                    
                    uModel1->addCollisionContactPoint(pointA);
                    uModel2->addCollisionContactPoint(pointA);
                    
                    break;
                }else if (n.pointB.distanceSquareBetweenPoints(uClosestPoint)<U4DEngine::closestDistanceToSimplexEpsilon){
                    //return one point as contact point
                    
                    U4DVector3n pointB=n.pointB.toVector();
                    
                    uModel1->addCollisionContactPoint(pointB);
                    uModel2->addCollisionContactPoint(pointB);
                    
                    break;
                }
                
                //return two points as contact point if segment is close to closestPoint from GJK
                
                U4DVector3n pointA=n.pointA.toVector();
                U4DVector3n pointB=n.pointB.toVector();
                
                
                uModel1->addCollisionContactPoint(pointA);
                uModel1->addCollisionContactPoint(pointB);
                
                uModel2->addCollisionContactPoint(pointA);
                uModel2->addCollisionContactPoint(pointB);
                
                
                break;
            }//end if
            
            //if no segment was close to the closest point from the GJK, then add the points into the vector
            U4DVector3n point=n.pointA.toVector();
            
            uModel1->addCollisionContactPoint(point);
            uModel2->addCollisionContactPoint(point);
           
            
        }//end for
        
        
        return true;
    }
    
    std::vector<CONTACTFACES> U4DSHAlgorithm::mostParallelFacesToPlane(U4DDynamicModel* uModel, U4DPlane& uPlane){
        
        std::vector<CONTACTFACES> modelFaces; //faces of each polygon in the model
        
        float parallelToPlane=-FLT_MIN;
        float support=0.0;
        
        U4DVector3n planeNormal=uPlane.n;
        
        //Normalize the plane so the dot product between the face normal and the plane falls within [-1,1]
        planeNormal.normalize();
        
        for(auto n: uModel->bodyCoordinates.getFacesDataFromContainer()){
            
            //update all faces with current model position
            
            U4DVector3n vertexA=n.pointA.toVector();
            U4DVector3n vertexB=n.pointB.toVector();
            U4DVector3n vertexC=n.pointC.toVector();
            
            vertexA=uModel->getAbsoluteMatrixOrientation()*vertexA;
            vertexA=vertexA+uModel->getAbsolutePosition();
            
            vertexB=uModel->getAbsoluteMatrixOrientation()*vertexB;
            vertexB=vertexB+uModel->getAbsolutePosition();
            
            vertexC=uModel->getAbsoluteMatrixOrientation()*vertexC;
            vertexC=vertexC+uModel->getAbsolutePosition();
            
            n.pointA=vertexA.toPoint();
            n.pointB=vertexB.toPoint();
            n.pointC=vertexC.toPoint();
            
            //structure to store all faces
            CONTACTFACES modelFace;
            
            //store triangle
            modelFace.triangle=n;
            
            //get the normal for the face & normalize
            U4DVector3n faceNormal=n.getTriangleNormal();
            
            //Normalize the face normal vector so the dot product between the face normal and the plane falls within [-1,1]
            faceNormal.normalize();
        
            //get the minimal dot product
            support=faceNormal.dot(planeNormal);
            
            modelFace.dotProduct=support;
            
            modelFaces.push_back(modelFace);
            
            //parallelToPlane keeps track of the most parallel dot product between the triangle normal vector and the plane normal
            
            if(support>parallelToPlane){
                
                parallelToPlane=support;
                
            }
            
        }

        //remove all faces with dot product not equal to most parallel face to plane
        modelFaces.erase(std::remove_if(modelFaces.begin(), modelFaces.end(),[parallelToPlane](CONTACTFACES &e){ return !(fabs(e.dotProduct - parallelToPlane) <= U4DEngine::zeroEpsilon * std::max(1.0f, std::max(e.dotProduct, parallelToPlane)));} ),modelFaces.end());
        
        
        return modelFaces;
        
    }
    
    std::vector<U4DTriangle> U4DSHAlgorithm::projectFacesToPlane(std::vector<CONTACTFACES>& uFaces, U4DPlane& uPlane){
        
        std::vector<U4DTriangle> projectedTriangles;
        
        for(auto n:uFaces){
           
            U4DTriangle triangle=n.triangle.projectTriangleOntoPlane(uPlane);
            
            projectedTriangles.push_back(triangle);
        }
        
        return projectedTriangles;
    }
    
    std::vector<CONTACTEDGE> U4DSHAlgorithm::getEdgesFromFaces(std::vector<U4DTriangle>& uFaces, U4DPlane& uPlane){
        
        std::vector<CONTACTEDGE> modelEdges;
    
        //For each face, get its corresponding edges
        
        for(auto n:uFaces){
            
            std::vector<U4DSegment> segment=n.getSegments();
            
            CONTACTEDGE modelEdgeAB;
            CONTACTEDGE modelEdgeBC;
            CONTACTEDGE modelEdgeCA;
            
            modelEdgeAB.segment=segment.at(0);
            modelEdgeBC.segment=segment.at(1);
            modelEdgeCA.segment=segment.at(2);
            
            modelEdgeAB.isDuplicate=false;
            modelEdgeBC.isDuplicate=false;
            modelEdgeCA.isDuplicate=false;
            
            std::vector<CONTACTEDGE> tempEdges{modelEdgeAB,modelEdgeBC,modelEdgeCA};
            
            if (modelEdges.size()==0) {
                
                modelEdges=tempEdges;
                
            }else{
             
                for(auto& edge:modelEdges){
                    
                    for(auto& tempEdge:tempEdges){
                        
                        //check if there are duplicate edges
                        if (edge.segment==tempEdge.segment || edge.segment==tempEdge.segment.negate()) {
                            
                            edge.isDuplicate=true;
                            tempEdge.isDuplicate=true;
                            
                        }
                        
                    }
                }
                
                modelEdges.push_back(tempEdges.at(0));
                modelEdges.push_back(tempEdges.at(1));
                modelEdges.push_back(tempEdges.at(2));
                
            }
            
        }
        
        //remove all duplicate faces
        modelEdges.erase(std::remove_if(modelEdges.begin(), modelEdges.end(),[](CONTACTEDGE &e){ return e.isDuplicate;} ),modelEdges.end());
        
        //Since the triangle was broken up, it also broke the CCW direction of all segments.
        //We need to connect the segments in a CCW direction
        std::vector<CONTACTEDGE> tempModelEdges;
        
        //use the first value in the container as the pivot segment
        int pivotIndex=0;
        
        tempModelEdges.push_back(modelEdges.at(pivotIndex));
        
        for (int pivot=0; pivot<modelEdges.size(); pivot++) {
            
            U4DSegment pivotSegment=modelEdges.at(pivotIndex).segment;
            
            for (int rotating=0; rotating<modelEdges.size(); rotating++) {
                
                //if I'm not testing the same segment and if the point B of the pivot segment is equal to the rotating pointB segment
                if ((pivotSegment.pointB==modelEdges.at(rotating).segment.pointA) &&(modelEdges.at(pivot).segment != modelEdges.at(rotating).segment)) {
                    
                    tempModelEdges.push_back(modelEdges.at(rotating));
                    pivotIndex=rotating;
                    
                    break;
                }
            }
            
        }
        
        modelEdges.clear();
        //copy the sorted CCW segments
        modelEdges=tempModelEdges;
        
        //calculate the normal of the line by doing a cross product between the plane normal and the segment direction
        for(auto& n:modelEdges){
            
            std::vector<U4DPoint3n> points=n.segment.getPoints();
            
            //get points
            U4DPoint3n pointA=points.at(0);
            U4DPoint3n pointB=points.at(1);
            
            //compute line
            U4DVector3n line=pointA-pointB;
            
            //get normal
            U4DVector3n normal=uPlane.n.cross(line);
            
            //assign normal to model edge
            n.normal=normal;
            
        }
        
        return modelEdges;
        
    }
    

    std::vector<U4DSegment> U4DSHAlgorithm::clipPolygons(std::vector<CONTACTEDGE>& uReferencePolygons, std::vector<CONTACTEDGE>& uIncidentPolygons){
        
        std::vector<U4DSegment> clipEdges;
        std::vector<U4DPoint3n> clippedPoints;
        
        //copy the incident edges into the the clip edges
        for(auto n:uIncidentPolygons){
            
            clipEdges.push_back(n.segment);
            
        }
    
        
        for(auto referencePolygon:uReferencePolygons){
            
            U4DVector3n normal=referencePolygon.normal;
            U4DPoint3n pointOnPlane=referencePolygon.segment.pointA;
            
            //create plane
            U4DPlane referencePlane(normal,pointOnPlane);
            
            //For every segment determine the location of each point and the direction of the segment
            for(auto incidentEdges:clipEdges){
                
                //get the points in the segment
                std::vector<U4DPoint3n> incidentPoints=incidentEdges.getPoints();
                std::vector<POINTINFORMATION> pointsInformation;
                
                //determine the location of each point segment with respect to the plane normal
                for(int i=0; i<incidentPoints.size(); i++){
                    
                    float direction=referencePlane.magnitudeSquareOfPointToPlane(incidentPoints.at(i));
                    
                    POINTINFORMATION pointInformation;
                    
                    pointInformation.point=incidentPoints.at(i);
                    
                    if (direction>U4DEngine::zeroEpsilon) {
                        
                        pointInformation.location=insidePlane;
                    
                    }else{
                       
                        if (direction < -U4DEngine::zeroEpsilon) {
                            
                            pointInformation.location=outsidePlane;
                        
                        }else{
                           
                            pointInformation.location=boundaryPlane;
                        
                        }
                        
                    }
                    
                    //store the points information
                    pointsInformation.push_back(pointInformation);
                
                }//end for
                    
                //determine the direction of the segment
                CONTACTEDGEINFORMATION edgeInformation;
                edgeInformation.contactSegment=incidentEdges;
                
                //segment going from INSIDE of plane to OUTSIDE of plane
                if (pointsInformation.at(0).location==insidePlane && pointsInformation.at(1).location==outsidePlane) {
                    
                    edgeInformation.direction=inToOut;
                    
                //segment going from OUTSIDE of plane to INSIDE of plane
                }else if (pointsInformation.at(0).location==outsidePlane && pointsInformation.at(1).location==insidePlane){
                    
                    edgeInformation.direction=outToIn;
                    
                //segment going from INSIDE of plane to INSIDE of plane
                }else if (pointsInformation.at(0).location==insidePlane && pointsInformation.at(1).location==insidePlane){
                
                    edgeInformation.direction=inToIn;
                    
                //segment going from OUTSIDE of plane to OUTSIDE of plane
                }else if (pointsInformation.at(0).location==outsidePlane && pointsInformation.at(1).location==outsidePlane){
                    
                    edgeInformation.direction=outToOut;
                    
                //segment is in boundary
                }else{
                    
                    edgeInformation.direction=inBoundary;
                    
                }
                
                
                //clip the segment
                
                
                if (edgeInformation.direction==inToOut) {
                    //Add intersection point
                    U4DPoint3n intersectPoint;
                    
                    referencePlane.intersectSegment(incidentEdges, intersectPoint);
                    
                    clippedPoints.push_back(intersectPoint);
                    
                }else if (edgeInformation.direction==outToIn){
                    //Add intersection point and pointB
                    
                    U4DPoint3n intersectPoint;
                    
                    referencePlane.intersectSegment(incidentEdges, intersectPoint);
                    
                    
                    clippedPoints.push_back(intersectPoint);
                    clippedPoints.push_back(incidentEdges.pointB);
                    
                }else if (edgeInformation.direction==inToIn){
                    //Add pointB
                    
                    clippedPoints.push_back(incidentEdges.pointB);
                    
                }else if (edgeInformation.direction==outToOut){
                    //Add none
                    
                }else{
                    //edge is a boundary
                    //Add PointB
                    
                    clippedPoints.push_back(incidentEdges.pointB);
                    
                }
                
            }//end for-Segment
            
            //for each point in clippedPoints, connect them as segments and initialize them as clipped edges
            
            if (clippedPoints.size()>1) {
                
                clipEdges.clear();
                
                for(int i=0;i<clippedPoints.size()-1;){
                    
                    U4DSegment newSegment(clippedPoints.at(i),clippedPoints.at(i+1));
                    clipEdges.push_back(newSegment);
                    i=i+1;
                    
                }
                
                //close the polygon loop
                U4DSegment closeSegment(clippedPoints.at(clippedPoints.size()-1),clippedPoints.at(0));
                
                clipEdges.push_back(closeSegment);
                
            }
            
            clippedPoints.clear();
            
        }//end for
        
        return clipEdges;
    }
    
    
}

