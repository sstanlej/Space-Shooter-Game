# Space Shooter
Stanisław Liszewski

My first attempt at making a game in Godot Engine.
Game about shooting incoming asteroids and gaining as many points as possible.

Currently implemented:
- Player movement (WASD) and shooting (Space)
- Asteroid spawning in random sinusoid patterns in waves
- Shooting down an asteroid grants points
- 2 types of boosters spawn periodically:
  - Attack speed booster
  - Attack damage booster
- After losing all health (by colliding with asteroids), Game Over screen will show statistics. Pressing "R" will reset the game.

State of April 17:
- 10 second Wave system with few enemy spawning mechanics
- Upgrade shop between waves with upgrades to choose
- Game difficulty scaling over time affecting aspects of the spawning system
- UI overlay with player's health and score and shop UI
- Simple looping backround
- Asteroids and UFOs
- Simple debug system (holding shift and using WSAD controls the camera)
