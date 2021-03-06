//
//  GameScene.swift
//  Shooter
//
//  Created by Eric Internicola on 2/19/16.
//  Copyright © 2016 Eric Internicola. All rights reserved.
//

import SpriteKit

/// This is the Game Scene, it's where we play the game itself
class GameScene: SKScene {

    /// The player's character, the Tardis
    var player: Tardis?

    /// The Score Label
    var scoreLabel: SKLabelNode?

    /// The Main Label
    var mainLabel: SKLabelNode?

    /// Manages the configuration for how often to spawn enemies, projectile spawn rate, etc
    var config = LevelConfig.start()
    
    /// Initial score
    var score = 0

    let textColorHUD = UIColor(red: 0.95, green: 0.95, blue: 0.95, alpha: 1)

    /// Lifecycle: when this scene is presented in the SKView.
    ///
    /// - Parameter view: The SKView that is presenting us
    override func didMove(to view: SKView) {
        physicsWorld.contactDelegate = self
        backgroundColor = UIColor.black
        
        setupBackground()
        createNodes()

        startGame()
    }


    /// Handles the game over capabilities
    override func gameOver() {
        showGameOver()
        guard let player = player else {
            return
        }
        player.position.x = -200
        self.player = nil
        for child in children {
            child.gameOver()
        }
    }

    /// updates every so often, good for bookkeeping
    ///
    /// - Parameter currentTime: the time that the update occurred
    override func update(_ currentTime: TimeInterval) {
        for node in children {
            // Call to Custom Extension
            node.update()
        }
    }

}

// MARK: - Touch Events

extension GameScene {
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let touchLocation = touch.location(in: self)
            guard let player = player, player.alive else {
                self.player?.position.x = -200
                continue
            }
            player.position.x = touchLocation.x
        }
    }
}

// MARK: - SKPhysicsContactDelegate Methods

extension GameScene : SKPhysicsContactDelegate {

    /// Handles physics contact
    ///
    /// - Parameter contact: the contact event
    func didBegin(_ contact: SKPhysicsContact) {
        guard let nodeA = contact.bodyA.node, let nodeB = contact.bodyB.node else {
            return
        }

        if let contactNode = nodeA as? PhysicsContactable {
            contactNode.handleContactWith(node: nodeB)
            return
        }
        if let contactNode = nodeB as? PhysicsContactable {
            contactNode.handleContactWith(node: nodeA)
        }
    }
}

// MARK: - Node Creation Methods

extension GameScene {

    func setupBackground() {
        guard let view = view else {
            return
        }
        var background: SKSpriteNode?
        if UIDevice.current.userInterfaceIdiom == .pad {
            if view.frame.height > view.frame.width {
                background = SKSpriteNode(texture: SKTexture.background1iPadPortrait)
                background?.xScale = 1.2
                background?.yScale = 1.2
            } else {
                background = SKSpriteNode(texture: SKTexture.background1iPadLandscape)
                background?.xScale = 1.5
                background?.yScale = 1.5
            }
        } else {
            background = SKSpriteNode(texture: SKTexture.background1)
            background?.xScale = 1.2
            background?.yScale = 1.2
        }
        guard let backgroundNode = background else {
            return
        }
        backgroundNode.position = CGPoint(x: frame.midX, y: frame.midY)
        backgroundNode.zPosition = -10
        backgroundNode.size = frame.size
        addChild(backgroundNode)
    }

    func spawnPlayer() {
        let player = Tardis()
        player.position = CGPoint(x: frame.midX, y: frame.minY + 100)
        addChild(player)

        self.player = player
    }

    func spawnEnemy() {
        guard let player = player, player.alive else {
            return
        }
        Dalek.enemySpeed = config.enemySpeed

        let enemy = Dalek()
        addChild(enemy)
        enemy.setRandomPosition()
    }

    func createScoreLabel() {
        scoreLabel = SKLabelNode(fontNamed: "Futura")
        if let scoreLabel = scoreLabel {
            scoreLabel.fontSize = 50
            scoreLabel.fontColor = textColorHUD
            scoreLabel.position = CGPoint(x: frame.midX, y: 5)
            scoreLabel.text = "Score"
            addChild(scoreLabel)
        }
    }

    func createMainLabel() {
        mainLabel = SKLabelNode(fontNamed: "Futura")
        if let mainLabel = mainLabel {
            mainLabel.fontSize = 100
            mainLabel.fontColor = textColorHUD
            mainLabel.position = CGPoint(x: frame.midX, y: frame.midY)
            mainLabel.text = "Start"

            addChild(mainLabel)
        }
    }

    func spawnProjectile() {
        guard let player = player else {
            return
        }
        let projectile = Projectile(player: player)
        addChild(projectile)
        let moveForward = SKAction.moveTo(y: frame.maxY, duration: config.projectileSpeed)
        projectile.run(SKAction.sequence([moveForward, SKAction.removeFromParent()]))
    }
}

// MARK: - Spawning Timers

extension GameScene {
    
    /// Fires a projectile upwards towards the Daleks
    func fireProjectile() {
        let fireProjectileTimer = SKAction.wait(forDuration: config.projectileRate)
        let spawn = SKAction.run {
            self.spawnProjectile()
        }
        let sequence = SKAction.sequence([fireProjectileTimer, spawn])
        run(SKAction.repeatForever(sequence))
    }

    /// Spawns a timer every so often
    func enemyTimerSpawn() {
        let spawnEnemyTimer = SKAction.wait(forDuration: config.enemySpawnRate)
        let spawn = SKAction.run {
            self.spawnEnemy()
        }
        let sequence = SKAction.sequence([spawnEnemyTimer, spawn])
        run(SKAction.repeatForever(sequence))
    }
}


// MARK: - Helper Methods

extension GameScene {

    /// Shows the Game Over message
    func showGameOver() {
        guard let mainLabel = mainLabel else {
            return
        }

        mainLabel.text = "Game Over"
        mainLabel.removeAllActions()
        mainLabel.fontSize = 50
        mainLabel.alpha = 1.0

        waitThenMoveToTitleScreen()
    }

    /// Tracks enemy kills for points
    ///
    /// - Parameter points: How many points was the kill worth?
    func killedEnemyFor(points: Int) {
        score += points
        updateScore()
    }

    /// Starts the game up
    func startGame() {
        fireProjectile()
        enemyTimerSpawn()
        updateScore()
        hideMainLabel()
    }

    /// Creates the nodes for gameplay
    func createNodes() {
        spawnPlayer()
        spawnEnemy()
        spawnProjectile()

        createScoreLabel()
        createMainLabel()
    }

    /// After a short delay, transitions back to the Title Scene
    func waitThenMoveToTitleScreen() {
        let transition = SKAction.run {
            guard let view = self.view else {
                return
            }
            let titleScene = TitleScene(size: view.frame.size)
            view.ignoresSiblingOrder = true
            titleScene.scaleMode = .aspectFill
            view.presentScene(titleScene, transition: SKTransition.crossFade(withDuration: 1.0))
        }
        let sequence = SKAction.sequence([SKAction.wait(forDuration: 3), transition])
        run(SKAction.repeat(sequence, count: 1))
    }

    /// Updates the score label with the current score
    func updateScore() {
        if let scoreLabel = scoreLabel {
            scoreLabel.text = "Score: \(score)"
        }
    }
    
    /// Hides the main label
    func hideMainLabel() {
        guard let mainLabel = mainLabel else {
            return
        }
        mainLabel.run(SKAction.fadeOut(withDuration: 3))
    }
}

