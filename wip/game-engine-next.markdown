
## Move Mario around
The example code already provides some key handling, let's extend it and move Mario around the screen.

The broken texture is really bugging me, but I want to keep working on interesting stuff.

## Get the engine out
Next, I want to start separating the engine into different packages (I'm still on the plane and I don't remember 
how to create any submodules).

The engine will deal with everything low level, like initialization of the OpenGL infrastructure, create the resources, 
key handling and the game loop.

The game will provide a the definition of the resources to load, the game objects to create and some basic configuration.

## Fix the texture
I went through the texture loader and the sprite drawer. The issue was on the Sprite drawer, it used pixel values for 
the texture coordinate when it had to use range from 0 to 1. Piece of cake.

## Move it Mario
The current key handling wasn't cut it. It just moved Mario 1 pixel per key press and I needed him to move continuously 
while pressed. For this the component will have to be kept immutable and therefore it

## Let's give Mario a friend
I wanted to add