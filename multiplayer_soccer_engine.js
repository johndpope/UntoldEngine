/**
 * Multiplayer Soccer Game Engine with Team Support
 * Extends the gravity system to support multiple players, teams, and multiplayer functionality
 */

// Import base classes from previous gravity system
// (In a real implementation, these would be imported from separate files)

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

// Player Stats and Attributes System
class PlayerStats {
    constructor(config = {}) {
        this.speed = config.speed || 7.5;           // Base running speed
        this.acceleration = config.acceleration || 12; // How quickly player reaches max speed
        this.agility = config.agility || 8;         // Turning and direction change speed
        this.strength = config.strength || 7;       // Physical contests and tackling
        this.stamina = config.stamina || 100;       // Energy system
        this.maxStamina = config.maxStamina || 100;
        this.ballControl = config.ballControl || 8; // Ball handling accuracy
        this.shooting = config.shooting || 7;       // Shot power and accuracy
        this.passing = config.passing || 8;         // Pass accuracy and power
        this.defending = config.defending || 6;     // Tackle success rate
        
        // Positional modifiers
        this.position = config.position || 'midfielder';
        this.applyPositionalModifiers();
    }

    applyPositionalModifiers() {
        const modifiers = {
            goalkeeper: { defending: 9, speed: 6, shooting: 4 },
            defender: { defending: 9, strength: 9, speed: 6.5, shooting: 5 },
            midfielder: { passing: 9, stamina: 12, ballControl: 9 },
            forward: { shooting: 9, speed: 9, acceleration: 14, defending: 4 }
        };

        if (modifiers[this.position]) {
            Object.assign(this, { ...this, ...modifiers[this.position] });
        }
    }

    consumeStamina(amount) {
        this.stamina = Math.max(0, this.stamina - amount);
    }

    recoverStamina(amount) {
        this.stamina = Math.min(this.maxStamina, this.stamina + amount);
    }

    getSpeedMultiplier() {
        return 0.5 + (this.stamina / this.maxStamina) * 0.5; // 50-100% speed based on stamina
    }
}

// Enhanced Player class with team support
class MultiplayerPlayer {
    constructor(id, name, position, teamId, stats = {}) {
        this.id = id;
        this.name = name;
        this.teamId = teamId;
        this.position = new Vector3(position.x, position.y, position.z);
        this.velocity = new Vector3();
        this.acceleration = new Vector3();
        
        this.stats = new PlayerStats({ ...stats, position: stats.position || 'midfielder' });
        this.mass = 75.0;
        this.radius = 0.3;
        this.restitution = 0.1;
        this.friction = 0.98;
        
        // Player state
        this.isGrounded = true;
        this.isJumping = false;
        this.hasBall = false;
        this.ballControlTime = 0;
        this.lastAction = null;
        this.isSliding = false;
        this.slideTime = 0;
        
        // AI/Control state
        this.isAI = true;
        this.playerId = null; // Human player ID if controlled by human
        this.targetPosition = this.position.copy();
        this.currentAction = 'idle';
        
        // Animation and visual state
        this.animationState = 'idle';
        this.facing = new Vector3(1, 0, 0); // Direction player is facing
    }

    // Apply force to player with stamina consideration
    applyForce(force) {
        const staminaMultiplier = this.stats.getSpeedMultiplier();
        const adjustedForce = force.multiply(staminaMultiplier);
        const acceleration = adjustedForce.multiply(1 / this.mass);
        this.acceleration = this.acceleration.add(acceleration);
    }

    // Enhanced movement with stats
    move(direction, intensity = 1.0) {
        if (this.isSliding) return; // Can't move while sliding
        
        const maxForce = this.stats.speed * this.stats.acceleration * intensity;
        const currentSpeed = this.velocity.magnitude();
        const maxSpeed = this.stats.speed * this.stats.getSpeedMultiplier();
        
        if (currentSpeed < maxSpeed) {
            const moveForce = direction.normalize().multiply(maxForce);
            this.applyForce(moveForce);
            
            // Update facing direction
            if (direction.magnitude() > 0.1) {
                this.facing = direction.normalize();
            }
            
            // Consume stamina based on intensity
            this.stats.consumeStamina(intensity * 0.1);
            this.animationState = intensity > 0.7 ? 'running' : 'walking';
        }
    }

    // Enhanced jumping with stats
    jump() {
        if (this.isGrounded && !this.isJumping && this.stats.stamina > 10) {
            const jumpForce = 1000 + (this.stats.strength * 50);
            this.applyForce(new Vector3(0, jumpForce, 0));
            this.isGrounded = false;
            this.isJumping = true;
            this.stats.consumeStamina(10);
            this.animationState = 'jumping';
        }
    }

    // Slide tackle
    slidetackle(direction) {
        if (!this.isSliding && this.isGrounded && this.stats.stamina > 20) {
            this.isSliding = true;
            this.slideTime = 1.0; // 1 second slide duration
            const slideForce = direction.normalize().multiply(800);
            this.applyForce(slideForce);
            this.stats.consumeStamina(20);
            this.animationState = 'sliding';
            return true;
        }
        return false;
    }

    // Update player physics and state
    update(deltaTime) {
        // Update slide state
        if (this.isSliding) {
            this.slideTime -= deltaTime;
            if (this.slideTime <= 0) {
                this.isSliding = false;
                this.animationState = 'idle';
            }
        }

        // Apply physics
        this.velocity = this.velocity.add(this.acceleration.multiply(deltaTime));
        this.position = this.position.add(this.velocity.multiply(deltaTime));
        this.acceleration = new Vector3();

        // Apply friction when grounded
        if (this.isGrounded) {
            this.velocity.x *= this.friction;
            this.velocity.z *= this.friction;
        }

        // Recover stamina over time
        if (!this.isSliding && this.velocity.magnitude() < 2) {
            this.stats.recoverStamina(deltaTime * 5);
        }

        // Update ball control time
        if (this.hasBall) {
            this.ballControlTime += deltaTime;
        } else {
            this.ballControlTime = 0;
        }
    }

    // Get player's effective radius for different actions
    getActionRadius(action) {
        const baseRadius = this.radius;
        switch (action) {
            case 'kick': return baseRadius + 0.5;
            case 'tackle': return this.isSliding ? baseRadius + 1.0 : baseRadius + 0.3;
            case 'pass': return baseRadius + 0.4;
            case 'intercept': return baseRadius + 0.2;
            default: return baseRadius;
        }
    }
}

// Team Management System
class Team {
    constructor(id, name, color, formation = '4-4-2') {
        this.id = id;
        this.name = name;
        this.color = color;
        this.formation = formation;
        this.players = [];
        this.score = 0;
        this.side = 'left'; // 'left' or 'right' side of field
        
        // Team statistics
        this.stats = {
            possession: 0,
            shots: 0,
            shotsOnTarget: 0,
            passes: 0,
            passAccuracy: 0,
            tackles: 0,
            fouls: 0
        };
        
        // Formation positions
        this.formationPositions = this.getFormationPositions(formation);
    }

    addPlayer(player) {
        player.teamId = this.id;
        this.players.push(player);
        this.assignFormationPosition(player);
    }

    removePlayer(playerId) {
        this.players = this.players.filter(p => p.id !== playerId);
    }

    getFormationPositions(formation) {
        const formations = {
            '4-4-2': [
                { position: 'goalkeeper', x: -40, z: 0 },
                { position: 'defender', x: -25, z: -15 },
                { position: 'defender', x: -25, z: -5 },
                { position: 'defender', x: -25, z: 5 },
                { position: 'defender', x: -25, z: 15 },
                { position: 'midfielder', x: -10, z: -10 },
                { position: 'midfielder', x: -10, z: -3 },
                { position: 'midfielder', x: -10, z: 3 },
                { position: 'midfielder', x: -10, z: 10 },
                { position: 'forward', x: 5, z: -5 },
                { position: 'forward', x: 5, z: 5 }
            ],
            '4-3-3': [
                { position: 'goalkeeper', x: -40, z: 0 },
                { position: 'defender', x: -25, z: -15 },
                { position: 'defender', x: -25, z: -5 },
                { position: 'defender', x: -25, z: 5 },
                { position: 'defender', x: -25, z: 15 },
                { position: 'midfielder', x: -10, z: -8 },
                { position: 'midfielder', x: -10, z: 0 },
                { position: 'midfielder', x: -10, z: 8 },
                { position: 'forward', x: 10, z: -10 },
                { position: 'forward', x: 10, z: 0 },
                { position: 'forward', x: 10, z: 10 }
            ]
        };
        return formations[formation] || formations['4-4-2'];
    }

    assignFormationPosition(player) {
        const availablePositions = this.formationPositions.filter(pos => 
            !this.players.find(p => p !== player && p.formationPosition === pos)
        );
        
        if (availablePositions.length > 0) {
            player.formationPosition = availablePositions[0];
            // Adjust for team side
            const sideMultiplier = this.side === 'right' ? -1 : 1;
            player.targetPosition = new Vector3(
                player.formationPosition.x * sideMultiplier,
                0,
                player.formationPosition.z
            );
        }
    }

    switchSides() {
        this.side = this.side === 'left' ? 'right' : 'left';
        this.players.forEach(player => {
            if (player.formationPosition) {
                const sideMultiplier = this.side === 'right' ? -1 : 1;
                player.targetPosition = new Vector3(
                    player.formationPosition.x * sideMultiplier,
                    0,
                    player.formationPosition.z
                );
            }
        });
    }

    getPlayerInPosition(position) {
        return this.players.find(p => p.formationPosition?.position === position);
    }

    getAllPlayers() {
        return [...this.players];
    }
}

// Enhanced Ball class with team interaction
class TeamSoccerBall {
    constructor(position) {
        this.position = position.copy();
        this.velocity = new Vector3();
        this.acceleration = new Vector3();
        this.mass = 0.45;
        this.radius = 0.11;
        this.restitution = 0.6;
        this.airResistance = 0.999;
        this.spinDecay = 0.99;
        this.spin = new Vector3();
        
        // Ball possession tracking
        this.lastTouchedBy = null;
        this.lastTouchedTeam = null;
        this.possessionTime = 0;
        this.isInPlay = true;
        this.lastTouchTime = 0;
    }

    applyKick(force, spinForce = new Vector3(), player = null) {
        this.applyForce(force);
        this.spin = this.spin.add(spinForce);
        
        if (player) {
            this.lastTouchedBy = player.id;
            this.lastTouchedTeam = player.teamId;
            this.lastTouchTime = Date.now();
        }
    }

    applyForce(force) {
        const acceleration = force.multiply(1 / this.mass);
        this.acceleration = this.acceleration.add(acceleration);
    }

    update(deltaTime) {
        // Apply air resistance
        this.velocity = this.velocity.multiply(this.airResistance);
        
        // Apply Magnus force for ball curve
        if (this.spin.magnitude() > 0.1) {
            const magnusForce = this.calculateMagnusForce();
            this.applyForce(magnusForce);
        }
        
        // Decay spin over time
        this.spin = this.spin.multiply(this.spinDecay);
        
        // Update physics
        this.velocity = this.velocity.add(this.acceleration.multiply(deltaTime));
        this.position = this.position.add(this.velocity.multiply(deltaTime));
        this.acceleration = new Vector3();
    }

    calculateMagnusForce() {
        const spinCross = new Vector3(
            this.spin.y * this.velocity.z - this.spin.z * this.velocity.y,
            this.spin.z * this.velocity.x - this.spin.x * this.velocity.z,
            this.spin.x * this.velocity.y - this.spin.y * this.velocity.x
        );
        return spinCross.multiply(0.0001);
    }
}

// Game Field and Rules
class SoccerField {
    constructor() {
        // FIFA standard field dimensions (in meters)
        this.length = 105;
        this.width = 68;
        this.goalWidth = 7.32;
        this.goalHeight = 2.44;
        this.penaltyAreaLength = 16.5;
        this.penaltyAreaWidth = 40.32;
        this.centerCircleRadius = 9.15;
        
        // Field boundaries
        this.bounds = {
            minX: -this.length / 2,
            maxX: this.length / 2,
            minZ: -this.width / 2,
            maxZ: this.width / 2
        };
        
        // Goal areas
        this.goals = {
            left: {
                x: -this.length / 2,
                minZ: -this.goalWidth / 2,
                maxZ: this.goalWidth / 2
            },
            right: {
                x: this.length / 2,
                minZ: -this.goalWidth / 2,
                maxZ: this.goalWidth / 2
            }
        };
    }

    isInBounds(position) {
        return position.x >= this.bounds.minX && position.x <= this.bounds.maxX &&
               position.z >= this.bounds.minZ && position.z <= this.bounds.maxZ;
    }

    checkGoal(ballPosition) {
        // Check left goal
        if (ballPosition.x <= this.goals.left.x &&
            ballPosition.z >= this.goals.left.minZ &&
            ballPosition.z <= this.goals.left.maxZ) {
            return 'right'; // Right team scored
        }
        
        // Check right goal
        if (ballPosition.x >= this.goals.right.x &&
            ballPosition.z >= this.goals.right.minZ &&
            ballPosition.z <= this.goals.right.maxZ) {
            return 'left'; // Left team scored
        }
        
        return null;
    }

    getOutOfBoundsType(ballPosition) {
        if (ballPosition.x < this.bounds.minX || ballPosition.x > this.bounds.maxX) {
            return 'goal_kick_or_corner';
        }
        if (ballPosition.z < this.bounds.minZ || ballPosition.z > this.bounds.maxZ) {
            return 'throw_in';
        }
        return null;
    }

    isInPenaltyArea(position, side) {
        if (side === 'left') {
            return position.x <= this.bounds.minX + this.penaltyAreaLength &&
                   position.z >= -this.penaltyAreaWidth / 2 &&
                   position.z <= this.penaltyAreaWidth / 2;
        } else {
            return position.x >= this.bounds.maxX - this.penaltyAreaLength &&
                   position.z >= -this.penaltyAreaWidth / 2 &&
                   position.z <= this.penaltyAreaWidth / 2;
        }
    }
}

// Multiplayer Game Manager
class MultiplayerSoccerGame {
    constructor() {
        this.field = new SoccerField();
        this.ball = new TeamSoccerBall(new Vector3(0, 1, 0));
        this.teams = new Map();
        this.players = new Map();
        
        // Game state
        this.gameState = 'kickoff'; // kickoff, playing, goal, halftime, fulltime
        this.gameTime = 0;
        this.halfDuration = 45 * 60; // 45 minutes in seconds
        this.currentHalf = 1;
        this.addedTime = 0;
        
        // Match statistics
        this.possession = { left: 0, right: 0 };
        this.lastPossessionCheck = 0;
        
        // Event system
        this.eventListeners = new Map();
        this.gameEvents = [];
        
        // Physics system
        this.gravity = new Vector3(0, -9.81, 0);
        this.groundLevel = 0;
        
        this.initializeDefaultTeams();
    }

    initializeDefaultTeams() {
        // Create two default teams
        const team1 = new Team('team1', 'Team Red', '#FF4444');
        team1.side = 'left';
        const team2 = new Team('team2', 'Team Blue', '#4444FF');
        team2.side = 'right';
        
        this.teams.set('team1', team1);
        this.teams.set('team2', team2);
        
        // Add default players
        this.createDefaultPlayers();
    }

    createDefaultPlayers() {
        const team1 = this.teams.get('team1');
        const team2 = this.teams.get('team2');
        
        // Create players for both teams
        for (let i = 0; i < 11; i++) {
            // Team 1 players
            const player1 = new MultiplayerPlayer(
                `player_${team1.id}_${i}`,
                `Player ${i + 1}`,
                new Vector3(-20 - i * 3, 0, (i - 5) * 3),
                team1.id,
                { position: this.getPositionForIndex(i) }
            );
            
            // Team 2 players
            const player2 = new MultiplayerPlayer(
                `player_${team2.id}_${i}`,
                `Player ${i + 1}`,
                new Vector3(20 + i * 3, 0, (i - 5) * 3),
                team2.id,
                { position: this.getPositionForIndex(i) }
            );
            
            this.addPlayer(player1, team1.id);
            this.addPlayer(player2, team2.id);
        }
    }

    getPositionForIndex(index) {
        const positions = ['goalkeeper', 'defender', 'defender', 'defender', 'defender',
                          'midfielder', 'midfielder', 'midfielder', 'midfielder',
                          'forward', 'forward'];
        return positions[index] || 'midfielder';
    }

    addPlayer(player, teamId) {
        const team = this.teams.get(teamId);
        if (team && team.players.length < 11) {
            team.addPlayer(player);
            this.players.set(player.id, player);
            return true;
        }
        return false;
    }

    removePlayer(playerId) {
        const player = this.players.get(playerId);
        if (player) {
            const team = this.teams.get(player.teamId);
            if (team) {
                team.removePlayer(playerId);
            }
            this.players.delete(playerId);
            return true;
        }
        return false;
    }

    // Handle player input/actions
    handlePlayerAction(playerId, action, data = {}) {
        const player = this.players.get(playerId);
        if (!player || this.gameState !== 'playing') return false;

        switch (action) {
            case 'move':
                player.move(new Vector3(data.x || 0, 0, data.z || 0), data.intensity || 1.0);
                break;
            case 'jump':
                player.jump();
                break;
            case 'slide':
                player.slidetackle(new Vector3(data.x || 0, 0, data.z || 0));
                break;
            case 'kick':
                this.handlePlayerKick(player, data);
                break;
            case 'pass':
                this.handlePlayerPass(player, data);
                break;
            case 'tackle':
                this.handlePlayerTackle(player);
                break;
        }
        
        this.emitEvent('playerAction', { playerId, action, data });
        return true;
    }

    handlePlayerKick(player, data) {
        const ballDistance = this.calculateDistance(player.position, this.ball.position);
        if (ballDistance <= player.getActionRadius('kick')) {
            const direction = new Vector3(data.x || 1, data.y || 0.2, data.z || 0);
            const power = Math.min(data.power || 800, 1500);
            const accuracy = player.stats.shooting / 10;
            
            // Add some randomness based on player skill
            const randomFactor = (1 - accuracy) * 0.3;
            const randomDirection = new Vector3(
                (Math.random() - 0.5) * randomFactor,
                (Math.random() - 0.5) * randomFactor * 0.5,
                (Math.random() - 0.5) * randomFactor
            );
            
            const finalDirection = direction.add(randomDirection);
            const spin = new Vector3(data.spin?.x || 0, data.spin?.y || 0, data.spin?.z || 0);
            
            this.ball.applyKick(finalDirection.normalize().multiply(power), spin, player);
            
            // Update team stats
            const team = this.teams.get(player.teamId);
            if (team) {
                team.stats.shots++;
                // Check if it's on target (simplified)
                if (Math.abs(finalDirection.z) < 3.66) { // Goal width
                    team.stats.shotsOnTarget++;
                }
            }
            
            this.emitEvent('ballKicked', { player, direction: finalDirection, power });
        }
    }

    handlePlayerPass(player, data) {
        const ballDistance = this.calculateDistance(player.position, this.ball.position);
        if (ballDistance <= player.getActionRadius('pass')) {
            const targetPlayer = this.players.get(data.targetPlayerId);
            if (targetPlayer && targetPlayer.teamId === player.teamId) {
                const passDirection = targetPlayer.position.add(player.position.multiply(-1)).normalize();
                const passPower = Math.min(data.power || 400, 800);
                const accuracy = player.stats.passing / 10;
                
                // Add accuracy variation
                const randomFactor = (1 - accuracy) * 0.2;
                const randomDirection = new Vector3(
                    (Math.random() - 0.5) * randomFactor,
                    0,
                    (Math.random() - 0.5) * randomFactor
                );
                
                const finalDirection = passDirection.add(randomDirection);
                this.ball.applyKick(finalDirection.normalize().multiply(passPower), new Vector3(), player);
                
                // Update team stats
                const team = this.teams.get(player.teamId);
                if (team) {
                    team.stats.passes++;
                    // Simple accuracy check
                    if (randomFactor < 0.1) {
                        team.stats.passAccuracy = (team.stats.passAccuracy * (team.stats.passes - 1) + 1) / team.stats.passes;
                    }
                }
                
                this.emitEvent('ballPassed', { player, targetPlayer, direction: finalDirection });
            }
        }
    }

    handlePlayerTackle(player) {
        // Find nearby opponents
        const nearbyOpponents = this.getNearbyOpponents(player, player.getActionRadius('tackle'));
        
        nearbyOpponents.forEach(opponent => {
            const tackleSuccess = Math.random() < (player.stats.defending / 15);
            if (tackleSuccess) {
                // Successful tackle - apply force to opponent
                const tackleDirection = opponent.position.add(player.position.multiply(-1)).normalize();
                opponent.applyForce(tackleDirection.multiply(300));
                
                // If opponent has ball, they lose it
                if (opponent.hasBall) {
                    opponent.hasBall = false;
                    this.ball.velocity = this.ball.velocity.add(tackleDirection.multiply(200));
                }
                
                this.emitEvent('tackle', { tackler: player, tackled: opponent, success: true });
            } else {
                // Failed tackle - possible foul
                const foulChance = 0.3;
                if (Math.random() < foulChance) {
                    this.emitEvent('foul', { fouler: player, fouled: opponent });
                }
            }
        });
    }

    // Game update loop
    update(deltaTime) {
        if (this.gameState === 'playing') {
            this.gameTime += deltaTime;
            this.updatePossession();
        }

        // Update all players
        this.players.forEach(player => {
            this.updatePlayerPhysics(player, deltaTime);
            player.update(deltaTime);
            
            // Check ball possession
            this.checkBallPossession(player);
        });

        // Update ball physics
        this.updateBallPhysics(deltaTime);

        // Check game events
        this.checkGoals();
        this.checkOutOfBounds();
        this.checkGameTime();

        // Update AI players
        this.updateAIPlayers(deltaTime);
    }

    updatePlayerPhysics(player, deltaTime) {
        // Apply gravity
        const gravityForce = this.gravity.multiply(player.mass);
        player.applyForce(gravityForce);

        // Handle ground collision
        if (player.position.y - player.radius <= this.groundLevel) {
            player.position.y = this.groundLevel + player.radius;
            if (player.velocity.y < 0) {
                player.velocity.y = -player.velocity.y * player.restitution;
                if (Math.abs(player.velocity.y) < 0.5) {
                    player.velocity.y = 0;
                    player.isGrounded = true;
                    player.isJumping = false;
                }
            }
        } else {
            player.isGrounded = false;
        }

        // Keep players in bounds
        this.keepPlayerInBounds(player);
    }

    updateBallPhysics(deltaTime) {
        // Apply gravity to ball
        const gravityForce = this.gravity.multiply(this.ball.mass);
        this.ball.applyForce(gravityForce);

        // Handle ground collision
        if (this.ball.position.y - this.ball.radius <= this.groundLevel) {
            this.ball.position.y = this.groundLevel + this.ball.radius;
            if (this.ball.velocity.y < 0) {
                this.ball.velocity.y = -this.ball.velocity.y * this.ball.restitution;
                if (Math.abs(this.ball.velocity.y) < 0.3) {
                    this.ball.velocity.y = 0;
                }
            }
        }

        this.ball.update(deltaTime);
    }

    checkBallPossession(player) {
        const ballDistance = this.calculateDistance(player.position, this.ball.position);
        const possessionRadius = 0.8;
        
        if (ballDistance <= possessionRadius && this.ball.velocity.magnitude() < 3) {
            // Clear possession from all other players
            this.players.forEach(p => p.hasBall = false);
            player.hasBall = true;
            this.ball.lastTouchedBy = player.id;
            this.ball.lastTouchedTeam = player.teamId;
        } else if (ballDistance > possessionRadius * 1.5) {
            player.hasBall = false;
        }
    }

    updatePossession() {
        if (this.ball.lastTouchedTeam) {
            const currentTime = Date.now();
            if (currentTime - this.lastPossessionCheck > 1000) { // Update every second
                const team = this.teams.get(this.ball.lastTouchedTeam);
                if (team) {
                    if (team.side === 'left') {
                        this.possession.left += 1;
                    } else {
                        this.possession.right += 1;
                    }
                }
                this.lastPossessionCheck = currentTime;
            }
        }
    }

    checkGoals() {
        const goalSide = this.field.checkGoal(this.ball.position);
        if (goalSide && this.gameState === 'playing') {
            const scoringTeam = goalSide === 'left' ? this.teams.get('team1') : this.teams.get('team2');
            if (scoringTeam) {
                scoringTeam.score++;
                this.gameState = 'goal';
                this.emitEvent('goal', { 
                    team: scoringTeam, 
                    scorer: this.ball.lastTouchedBy,
                    gameTime: this.gameTime 
                });
                
                // Reset for kickoff
                setTimeout(() => {
                    this.resetForKickoff(goalSide === 'left' ? 'team2' : 'team1');
                }, 3000);
            }
        }
    }

    checkOutOfBounds() {
        if (!this.field.isInBounds(this.ball.position)) {
            const outType = this.field.getOutOfBoundsType(this.ball.position);
            this.emitEvent('outOfBounds', { 
                type: outType, 
                position: this.ball.position.copy(),
                lastTouchedTeam: this.ball.lastTouchedTeam 
            });
            
            // Reset ball to appropriate position
            this.handleOutOfBounds(outType);
        }
    }

    checkGameTime() {
        const halfTime = this.halfDuration + this.addedTime;
        
        if (this.gameTime >= halfTime && this.currentHalf === 1) {
            this.gameState = 'halftime';
            this.emitEvent('halftime', { gameTime: this.gameTime });
            
            setTimeout(() => {
                this.startSecondHalf();
            }, 15000); // 15 second halftime
        } else if (this.gameTime >= halfTime * 2 && this.currentHalf === 2) {
            this.gameState = 'fulltime';
            this.emitEvent('fulltime', { 
                finalScore: this.getFinalScore(),
                gameTime: this.gameTime 
            });
        }
    }

    updateAIPlayers(deltaTime) {
        this.players.forEach(player => {
            if (player.isAI && player.playerId === null) {
                this.updateAIBehavior(player, deltaTime);
            }
        });
    }

    updateAIBehavior(player, deltaTime) {
        const ballDistance = this.calculateDistance(player.position, this.ball.position);
        const team = this.teams.get(player.teamId);
        
        // Simple AI behavior based on position and ball location
        if (ballDistance < 5 && !player.hasBall) {
            // Move towards ball
            const ballDirection = this.ball.position.add(player.position.multiply(-1)).normalize();
            player.move(ballDirection, 0.8);
        } else if (player.hasBall) {
            // If player has ball, try to move towards opponent goal
            const opponentGoal = team.side === 'left' ? 
                new Vector3(this.field.length / 2, 0, 0) : 
                new Vector3(-this.field.length / 2, 0, 0);
            
            const goalDirection = opponentGoal.add(player.position.multiply(-1)).normalize();
            
            // Sometimes pass, sometimes dribble
            if (Math.random() < 0.1) { // 10% chance to pass
                const teammates = this.getTeammates(player);
                const nearestTeammate = this.findNearestPlayer(player.position, teammates);
                if (nearestTeammate) {
                    this.handlePlayerPass(player, { 
                        targetPlayerId: nearestTeammate.id, 
                        power: 400 
                    });
                }
            } else if (Math.random() < 0.05) { // 5% chance to shoot
                this.handlePlayerKick(player, { 
                    x: goalDirection.x, 
                    y: 0.3, 
                    z: goalDirection.z, 
                    power: 1000 
                });
            } else {
                // Dribble towards goal
                player.move(goalDirection, 0.6);
            }
        } else {
            // Return to formation position
            const targetDirection = player.targetPosition.add(player.position.multiply(-1));
            if (targetDirection.magnitude() > 2) {
                player.move(targetDirection.normalize(), 0.4);
            }
        }
    }

    // Utility methods
    calculateDistance(pos1, pos2) {
        const dx = pos1.x - pos2.x;
        const dy = pos1.y - pos2.y;
        const dz = pos1.z - pos2.z;
        return Math.sqrt(dx * dx + dy * dy + dz * dz);
    }

    getNearbyOpponents(player, radius) {
        const opponents = [];
        this.players.forEach(otherPlayer => {
            if (otherPlayer.teamId !== player.teamId) {
                const distance = this.calculateDistance(player.position, otherPlayer.position);
                if (distance <= radius) {
                    opponents.push(otherPlayer);
                }
            }
        });
        return opponents;
    }

    getTeammates(player) {
        const teammates = [];
        this.players.forEach(otherPlayer => {
            if (otherPlayer.teamId === player.teamId && otherPlayer.id !== player.id) {
                teammates.push(otherPlayer);
            }
        });
        return teammates;
    }

    findNearestPlayer(position, players) {
        let nearest = null;
        let minDistance = Infinity;
        
        players.forEach(player => {
            const distance = this.calculateDistance(position, player.position);
            if (distance < minDistance) {
                minDistance = distance;
                nearest = player;
            }
        });
        
        return nearest;
    }

    keepPlayerInBounds(player) {
        const buffer = 1; // 1 meter buffer from field edge
        
        if (player.position.x < this.field.bounds.minX + buffer) {
            player.position.x = this.field.bounds.minX + buffer;
            player.velocity.x = Math.max(0, player.velocity.x);
        }
        if (player.position.x > this.field.bounds.maxX - buffer) {
            player.position.x = this.field.bounds.maxX - buffer;
            player.velocity.x = Math.min(0, player.velocity.x);
        }
        if (player.position.z < this.field.bounds.minZ + buffer) {
            player.position.z = this.field.bounds.minZ + buffer;
            player.velocity.z = Math.max(0, player.velocity.z);
        }
        if (player.position.z > this.field.bounds.maxZ - buffer) {
            player.position.z = this.field.bounds.maxZ - buffer;
            player.velocity.z = Math.min(0, player.velocity.z);
        }
    }

    handleOutOfBounds(outType) {
        // Simplified out of bounds handling
        switch (outType) {
            case 'throw_in':
                // Place ball at side of field
                if (this.ball.position.z < 0) {
                    this.ball.position = new Vector3(this.ball.position.x, 1, this.field.bounds.minZ + 1);
                } else {
                    this.ball.position = new Vector3(this.ball.position.x, 1, this.field.bounds.maxZ - 1);
                }
                break;
            case 'goal_kick_or_corner':
                // Simplified: place ball in center
                this.ball.position = new Vector3(0, 1, 0);
                break;
        }
        this.ball.velocity = new Vector3();
        this.ball.isInPlay = true;
    }

    resetForKickoff(kickingTeamId) {
        // Reset ball to center
        this.ball.position = new Vector3(0, 1, 0);
        this.ball.velocity = new Vector3();
        this.ball.lastTouchedBy = null;
        this.ball.lastTouchedTeam = kickingTeamId;
        
        // Reset all players to formation positions
        this.teams.forEach(team => {
            team.players.forEach(player => {
                if (player.formationPosition) {
                    const sideMultiplier = team.side === 'right' ? -1 : 1;
                    player.position = new Vector3(
                        player.formationPosition.x * sideMultiplier,
                        0,
                        player.formationPosition.z
                    );
                    player.velocity = new Vector3();
                    player.hasBall = false;
                }
            });
        });
        
        this.gameState = 'playing';
    }

    startSecondHalf() {
        this.currentHalf = 2;
        this.gameTime = this.halfDuration;
        
        // Switch team sides
        this.teams.forEach(team => team.switchSides());
        
        // Reset for kickoff with opposite team
        const kickingTeam = this.ball.lastTouchedTeam === 'team1' ? 'team2' : 'team1';
        this.resetForKickoff(kickingTeam);
        
        this.emitEvent('secondHalfStart', { kickingTeam });
    }

    // Event system
    addEventListener(event, callback) {
        if (!this.eventListeners.has(event)) {
            this.eventListeners.set(event, []);
        }
        this.eventListeners.get(event).push(callback);
    }

    removeEventListener(event, callback) {
        if (this.eventListeners.has(event)) {
            const listeners = this.eventListeners.get(event);
            const index = listeners.indexOf(callback);
            if (index > -1) {
                listeners.splice(index, 1);
            }
        }
    }

    emitEvent(event, data) {
        const eventData = {
            type: event,
            timestamp: Date.now(),
            gameTime: this.gameTime,
            ...data
        };
        
        this.gameEvents.push(eventData);
        
        if (this.eventListeners.has(event)) {
            this.eventListeners.get(event).forEach(callback => {
                callback(eventData);
            });
        }
    }

    // Game state getters
    getGameState() {
        return {
            gameState: this.gameState,
            gameTime: this.gameTime,
            currentHalf: this.currentHalf,
            score: this.getScore(),
            possession: this.getPossessionPercentage(),
            ball: {
                position: this.ball.position,
                velocity: this.ball.velocity,
                lastTouchedBy: this.ball.lastTouchedBy,
                lastTouchedTeam: this.ball.lastTouchedTeam
            },
            teams: this.getTeamsData(),
            players: this.getPlayersData()
        };
    }

    getScore() {
        const team1 = this.teams.get('team1');
        const team2 = this.teams.get('team2');
        return {
            team1: team1 ? team1.score : 0,
            team2: team2 ? team2.score : 0
        };
    }

    getFinalScore() {
        return this.getScore();
    }

    getPossessionPercentage() {
        const total = this.possession.left + this.possession.right;
        if (total === 0) return { left: 50, right: 50 };
        
        return {
            left: Math.round((this.possession.left / total) * 100),
            right: Math.round((this.possession.right / total) * 100)
        };
    }

    getTeamsData() {
        const teamsData = {};
        this.teams.forEach((team, teamId) => {
            teamsData[teamId] = {
                id: team.id,
                name: team.name,
                color: team.color,
                score: team.score,
                side: team.side,
                formation: team.formation,
                stats: team.stats,
                playerCount: team.players.length
            };
        });
        return teamsData;
    }

    getPlayersData() {
        const playersData = {};
        this.players.forEach((player, playerId) => {
            playersData[playerId] = {
                id: player.id,
                name: player.name,
                teamId: player.teamId,
                position: player.position,
                velocity: player.velocity,
                hasBall: player.hasBall,
                isAI: player.isAI,
                playerId: player.playerId,
                animationState: player.animationState,
                facing: player.facing,
                stats: {
                    stamina: player.stats.stamina,
                    maxStamina: player.stats.maxStamina,
                    position: player.stats.position
                }
            };
        });
        return playersData;
    }

    // Player assignment for human players
    assignPlayerToHuman(playerId, humanId) {
        const player = this.players.get(playerId);
        if (player) {
            player.isAI = false;
            player.playerId = humanId;
            this.emitEvent('playerAssigned', { playerId, humanId });
            return true;
        }
        return false;
    }

    unassignPlayerFromHuman(playerId) {
        const player = this.players.get(playerId);
        if (player) {
            player.isAI = true;
            player.playerId = null;
            this.emitEvent('playerUnassigned', { playerId });
            return true;
        }
        return false;
    }

    // Match configuration
    setMatchDuration(minutes) {
        this.halfDuration = minutes * 60 / 2; // Convert to seconds and divide by 2 for each half
    }

    addExtraTime(seconds) {
        this.addedTime += seconds;
    }

    // Statistics and analytics
    getMatchStatistics() {
        const team1 = this.teams.get('team1');
        const team2 = this.teams.get('team2');
        
        return {
            duration: this.gameTime,
            possession: this.getPossessionPercentage(),
            team1Stats: team1 ? team1.stats : {},
            team2Stats: team2 ? team2.stats : {},
            events: this.gameEvents,
            finalScore: this.getScore()
        };
    }

    // Save and load game state (for reconnection support)
    saveGameState() {
        return {
            gameState: this.gameState,
            gameTime: this.gameTime,
            currentHalf: this.currentHalf,
            ball: {
                position: this.ball.position,
                velocity: this.ball.velocity,
                lastTouchedBy: this.ball.lastTouchedBy,
                lastTouchedTeam: this.ball.lastTouchedTeam
            },
            teams: this.getTeamsData(),
            players: this.getPlayersData(),
            possession: this.possession,
            events: this.gameEvents
        };
    }

    loadGameState(savedState) {
        this.gameState = savedState.gameState;
        this.gameTime = savedState.gameTime;
        this.currentHalf = savedState.currentHalf;
        
        // Restore ball state
        this.ball.position = new Vector3(savedState.ball.position.x, savedState.ball.position.y, savedState.ball.position.z);
        this.ball.velocity = new Vector3(savedState.ball.velocity.x, savedState.ball.velocity.y, savedState.ball.velocity.z);
        this.ball.lastTouchedBy = savedState.ball.lastTouchedBy;
        this.ball.lastTouchedTeam = savedState.ball.lastTouchedTeam;
        
        // Restore player positions and states
        Object.entries(savedState.players).forEach(([playerId, playerData]) => {
            const player = this.players.get(playerId);
            if (player) {
                player.position = new Vector3(playerData.position.x, playerData.position.y, playerData.position.z);
                player.velocity = new Vector3(playerData.velocity.x, playerData.velocity.y, playerData.velocity.z);
                player.hasBall = playerData.hasBall;
                player.isAI = playerData.isAI;
                player.playerId = playerData.playerId;
            }
        });
        
        this.possession = savedState.possession;
        this.gameEvents = savedState.events;
    }
}

// Network/Multiplayer Support Classes
class NetworkManager {
    constructor(game) {
        this.game = game;
        this.connections = new Map();
        this.updateRate = 60; // Updates per second
        this.lastUpdate = 0;
    }

    addConnection(connectionId, connection) {
        this.connections.set(connectionId, {
            connection: connection,
            playerId: null,
            lastPing: Date.now()
        });
    }

    removeConnection(connectionId) {
        const conn = this.connections.get(connectionId);
        if (conn && conn.playerId) {
            this.game.unassignPlayerFromHuman(conn.playerId);
        }
        this.connections.delete(connectionId);
    }

    handleMessage(connectionId, message) {
        const conn = this.connections.get(connectionId);
        if (!conn) return;

        switch (message.type) {
            case 'assignPlayer':
                if (this.game.assignPlayerToHuman(message.playerId, connectionId)) {
                    conn.playerId = message.playerId;
                }
                break;
            case 'playerAction':
                this.game.handlePlayerAction(conn.playerId, message.action, message.data);
                break;
            case 'ping':
                this.sendToConnection(connectionId, { type: 'pong', timestamp: message.timestamp });
                break;
        }
    }

    sendToConnection(connectionId, message) {
        const conn = this.connections.get(connectionId);
        if (conn && conn.connection) {
            conn.connection.send(JSON.stringify(message));
        }
    }

    broadcastGameState() {
        const currentTime = Date.now();
        if (currentTime - this.lastUpdate < (1000 / this.updateRate)) return;

        const gameState = this.game.getGameState();
        const message = {
            type: 'gameState',
            timestamp: currentTime,
            data: gameState
        };

        this.connections.forEach((conn, connectionId) => {
            this.sendToConnection(connectionId, message);
        });

        this.lastUpdate = currentTime;
    }
}

// Export for use in game engine
if (typeof module !== 'undefined' && module.exports) {
    module.exports = {
        Vector3,
        PlayerStats,
        MultiplayerPlayer,
        Team,
        TeamSoccerBall,
        SoccerField,
        MultiplayerSoccerGame,
        NetworkManager
    };
}

// Example usage
/*
const game = new MultiplayerSoccerGame();
const networkManager = new NetworkManager(game);

// Game loop
setInterval(() => {
    game.update(1/60); // 60 FPS
    networkManager.broadcastGameState();
}, 16);

// Event listeners
game.addEventListener('goal', (event) => {
    console.log(`Goal scored by ${event.team.name}!`);
});

game.addEventListener('playerAction', (event) => {
    console.log(`Player ${event.playerId} performed ${event.action}`);
});
*/