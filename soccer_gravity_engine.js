/**
 * Soccer Game Engine - Gravity and Physics System
 * Handles realistic gravity simulation for ball, players, and objects
 */

class Vector3 {
    constructor(x = 0, y = 0, z = 0) {
        this.x = x;
        this.y = y;
        this.z = z;
    }

    add(vector) {
        return new Vector3(this.x + vector.x, this.y + vector.y, this.z + vector.z);
    }

    multiply(scalar) {
        return new Vector3(this.x * scalar, this.y * scalar, this.z * scalar);
    }

    magnitude() {
        return Math.sqrt(this.x * this.x + this.y * this.y + this.z * this.z);
    }

    normalize() {
        const mag = this.magnitude();
        return mag > 0 ? new Vector3(this.x / mag, this.y / mag, this.z / mag) : new Vector3();
    }

    copy() {
        return new Vector3(this.x, this.y, this.z);
    }
}

class PhysicsObject {
    constructor(position, mass = 1.0, restitution = 0.7) {
        this.position = position.copy();
        this.velocity = new Vector3();
        this.acceleration = new Vector3();
        this.mass = mass;
        this.restitution = restitution; // Bounciness factor (0-1)
        this.radius = 0.5; // Default radius for collision detection
        this.isGrounded = false;
        this.friction = 0.98; // Surface friction
    }

    applyForce(force) {
        // F = ma, so a = F/m
        const acceleration = force.multiply(1 / this.mass);
        this.acceleration = this.acceleration.add(acceleration);
    }

    update(deltaTime) {
        // Update velocity based on acceleration
        this.velocity = this.velocity.add(this.acceleration.multiply(deltaTime));
        
        // Update position based on velocity
        this.position = this.position.add(this.velocity.multiply(deltaTime));
        
        // Reset acceleration (forces need to be applied each frame)
        this.acceleration = new Vector3();
    }
}

class SoccerBall extends PhysicsObject {
    constructor(position) {
        super(position, 0.45, 0.6); // FIFA ball weight ~450g, moderate bounce
        this.radius = 0.11; // FIFA ball radius ~11cm
        this.airResistance = 0.999; // Air drag coefficient
        this.spinDecay = 0.99; // How quickly spin decreases
        this.spin = new Vector3(); // Ball spin for curve effects
    }

    applyKick(force, spinForce = new Vector3()) {
        this.applyForce(force);
        this.spin = this.spin.add(spinForce);
    }

    update(deltaTime) {
        // Apply air resistance
        this.velocity = this.velocity.multiply(this.airResistance);
        
        // Apply Magnus force (ball curve due to spin)
        if (this.spin.magnitude() > 0.1) {
            const magnusForce = this.calculateMagnusForce();
            this.applyForce(magnusForce);
        }
        
        // Decay spin over time
        this.spin = this.spin.multiply(this.spinDecay);
        
        super.update(deltaTime);
    }

    calculateMagnusForce() {
        // Simplified Magnus effect calculation
        const spinCross = new Vector3(
            this.spin.y * this.velocity.z - this.spin.z * this.velocity.y,
            this.spin.z * this.velocity.x - this.spin.x * this.velocity.z,
            this.spin.x * this.velocity.y - this.spin.y * this.velocity.x
        );
        return spinCross.multiply(0.0001); // Scale factor for realistic effect
    }
}

class Player extends PhysicsObject {
    constructor(position) {
        super(position, 75.0, 0.1); // Average player weight ~75kg, low bounce
        this.radius = 0.3; // Player collision radius
        this.jumpForce = 1200; // Force applied when jumping
        this.maxSpeed = 8; // Maximum running speed (m/s)
        this.isJumping = false;
    }

    jump() {
        if (this.isGrounded && !this.isJumping) {
            this.applyForce(new Vector3(0, this.jumpForce, 0));
            this.isGrounded = false;
            this.isJumping = true;
        }
    }

    move(direction) {
        // Apply movement force, limited by max speed
        if (this.velocity.magnitude() < this.maxSpeed) {
            const moveForce = direction.normalize().multiply(500);
            this.applyForce(moveForce);
        }
    }
}

class GravitySystem {
    constructor() {
        this.gravity = new Vector3(0, -9.81, 0); // Earth gravity: 9.81 m/s²
        this.groundLevel = 0;
        this.objects = [];
        this.windForce = new Vector3(0, 0, 0); // Environmental wind
    }

    addObject(object) {
        this.objects.push(object);
    }

    removeObject(object) {
        const index = this.objects.indexOf(object);
        if (index > -1) {
            this.objects.splice(index, 1);
        }
    }

    setWind(windVector) {
        this.windForce = windVector;
    }

    update(deltaTime) {
        this.objects.forEach(obj => {
            // Apply gravity force
            const gravityForce = this.gravity.multiply(obj.mass);
            obj.applyForce(gravityForce);

            // Apply wind force (affects lighter objects more)
            const windEffect = this.windForce.multiply(1 / obj.mass);
            obj.applyForce(windEffect);

            // Update object physics
            obj.update(deltaTime);

            // Handle ground collision
            this.handleGroundCollision(obj);

            // Apply ground friction when on ground
            if (obj.isGrounded) {
                obj.velocity.x *= obj.friction;
                obj.velocity.z *= obj.friction;
            }
        });

        // Handle object-to-object collisions
        this.handleCollisions();
    }

    handleGroundCollision(obj) {
        if (obj.position.y - obj.radius <= this.groundLevel) {
            // Object hit the ground
            obj.position.y = this.groundLevel + obj.radius;
            
            if (obj.velocity.y < 0) {
                // Bounce with restitution
                obj.velocity.y = -obj.velocity.y * obj.restitution;
                
                // If bounce is very small, consider object grounded
                if (Math.abs(obj.velocity.y) < 0.5) {
                    obj.velocity.y = 0;
                    obj.isGrounded = true;
                    
                    if (obj instanceof Player) {
                        obj.isJumping = false;
                    }
                }
            }
        } else {
            obj.isGrounded = false;
        }
    }

    handleCollisions() {
        for (let i = 0; i < this.objects.length; i++) {
            for (let j = i + 1; j < this.objects.length; j++) {
                const obj1 = this.objects[i];
                const obj2 = this.objects[j];
                
                const distance = this.calculateDistance(obj1.position, obj2.position);
                const minDistance = obj1.radius + obj2.radius;
                
                if (distance < minDistance) {
                    this.resolveCollision(obj1, obj2, distance, minDistance);
                }
            }
        }
    }

    calculateDistance(pos1, pos2) {
        const dx = pos1.x - pos2.x;
        const dy = pos1.y - pos2.y;
        const dz = pos1.z - pos2.z;
        return Math.sqrt(dx * dx + dy * dy + dz * dz);
    }

    resolveCollision(obj1, obj2, distance, minDistance) {
        // Calculate collision normal
        const normal = new Vector3(
            (obj1.position.x - obj2.position.x) / distance,
            (obj1.position.y - obj2.position.y) / distance,
            (obj1.position.z - obj2.position.z) / distance
        );

        // Separate objects
        const overlap = minDistance - distance;
        const separation = normal.multiply(overlap * 0.5);
        
        obj1.position = obj1.position.add(separation);
        obj2.position = obj2.position.add(separation.multiply(-1));

        // Calculate relative velocity
        const relativeVelocity = new Vector3(
            obj1.velocity.x - obj2.velocity.x,
            obj1.velocity.y - obj2.velocity.y,
            obj1.velocity.z - obj2.velocity.z
        );

        // Calculate collision impulse
        const velocityAlongNormal = relativeVelocity.x * normal.x + 
                                   relativeVelocity.y * normal.y + 
                                   relativeVelocity.z * normal.z;

        if (velocityAlongNormal > 0) return; // Objects separating

        const restitution = Math.min(obj1.restitution, obj2.restitution);
        const impulseScalar = -(1 + restitution) * velocityAlongNormal / (1/obj1.mass + 1/obj2.mass);

        const impulse = normal.multiply(impulseScalar);

        // Apply impulse to velocities
        obj1.velocity = obj1.velocity.add(impulse.multiply(1/obj1.mass));
        obj2.velocity = obj2.velocity.add(impulse.multiply(-1/obj2.mass));
    }

    // Utility method to simulate a ball kick
    kickBall(ball, direction, power, spin = new Vector3()) {
        if (ball instanceof SoccerBall) {
            const kickForce = direction.normalize().multiply(power);
            ball.applyKick(kickForce, spin);
        }
    }

    // Get trajectory prediction for ball (useful for AI)
    predictTrajectory(ball, steps = 60, timeStep = 0.016) {
        const trajectory = [];
        const tempBall = new SoccerBall(ball.position);
        tempBall.velocity = ball.velocity.copy();
        tempBall.spin = ball.spin.copy();

        for (let i = 0; i < steps; i++) {
            const gravityForce = this.gravity.multiply(tempBall.mass);
            tempBall.applyForce(gravityForce);
            tempBall.update(timeStep);
            
            if (tempBall.position.y <= this.groundLevel + tempBall.radius) {
                tempBall.position.y = this.groundLevel + tempBall.radius;
                break;
            }
            
            trajectory.push(tempBall.position.copy());
        }

        return trajectory;
    }
}

// Example usage and game setup
class SoccerGame {
    constructor() {
        this.gravity = new GravitySystem();
        this.ball = new SoccerBall(new Vector3(0, 1, 0));
        this.players = [];
        
        // Add ball to physics system
        this.gravity.addObject(this.ball);
        
        // Create some players
        for (let i = 0; i < 4; i++) {
            const player = new Player(new Vector3(i * 3 - 4.5, 0, 0));
            this.players.push(player);
            this.gravity.addObject(player);
        }
    }

    update(deltaTime) {
        // Update physics
        this.gravity.update(deltaTime);
        
        // Add game-specific logic here
        this.handleInput();
        this.updateGameState();
    }

    handleInput() {
        // Example: Kick ball with first player
        // In a real game, this would be triggered by user input
        const player = this.players[0];
        const ballDistance = this.gravity.calculateDistance(player.position, this.ball.position);
        
        if (ballDistance < 1.0) { // Player can kick ball
            const kickDirection = new Vector3(1, 0.3, 0); // Forward and slightly up
            const kickPower = 800;
            const ballSpin = new Vector3(0, 0, 50); // Add some side spin
            
            this.gravity.kickBall(this.ball, kickDirection, kickPower, ballSpin);
        }
    }

    updateGameState() {
        // Check for goals, out of bounds, etc.
        // Update game score, time, etc.
    }

    // Get game state for rendering
    getGameState() {
        return {
            ball: this.ball,
            players: this.players,
            trajectory: this.gravity.predictTrajectory(this.ball)
        };
    }
}

// Export for use in game engine
if (typeof module !== 'undefined' && module.exports) {
    module.exports = {
        Vector3,
        PhysicsObject,
        SoccerBall,
        Player,
        GravitySystem,
        SoccerGame
    };
}