---
title: Functional Game engine in Scala, Part 1
---

I got interested again into starting some amusing project. I have always been interested a into game programming and now
that I am into Scala I thought that it would be fun to combine the two.

With a short vacation a two and a half hours flight ahead I decided to jump right into it to kill time.

## How do I approach this?
I'm used to work on web applications with REST endpoints and a database as a store. Creating a game engine is quite far
from that so although I have toyed with video game programming before I wanted to be clever on my approach. I decided I 
would start simple, create a small 2D game and start abstracting the engine from it.

## My goal
My goal is to develop a proof of concept of a functional game engine so I decided to use LWJGL for access to low level 
native libraries, like OpenGL. I'll abstract over this and provide higher level functions inside a functional framework!

## First step
The first thing I do it to grab the [example java code from LWJGL web](https://www.lwjgl.org/guide), allow Intellij to 
convert it to Scala and take it for a ride.

<img src="/images/posts/game-engine/greenfield.png" alt="Green background" class="img-50" />

This gives me a very nice green background, but I would like something more interesting...

Even though I plan the engine to support 3D I don't want to go anywhere close to 3D meshes right now. I will develop 
functionality as needed and a sprite based game is my starting choice. With this in mind I grab a Mario image and drop 
it in.
<img src="/images/posts/game-engine/mario.png" alt="Mario" class="img-20" />

## Add something to the green pasture
I'm​ not familiar with painting sprites using OpenGL. But it's easy to find some Java code for [LWJGL](https://www.lwjgl.org).

```scala
def draw(texture: Texture, x: Int, y: Int): Unit = {

    // bind to the appropriate texture for this sprite
    GL11.glBindTexture(GL11.GL_TEXTURE_2D, texture.id)
    // store the current model matrix
    GL11.glPushMatrix()
    // translate to the right location and prepare to draw
    GL11.glTranslatef(x, y, 0)
    GL11.glColor3f(1, 1, 1)
    // draw a quad textured to match the sprite
    GL11.glBegin(GL11.GL_QUADS)
    GL11.glTexCoord2f(0, 0)
    GL11.glVertex2f(0, 0)
    GL11.glTexCoord2f(0, texture.height)
    GL11.glVertex2f(0, height)
    GL11.glTexCoord2f(texture.width, texture.height)
    GL11.glVertex2f(width, height)
    GL11.glTexCoord2f(texture.width, 0)
    GL11.glVertex2f(width, 0)

    GL11.glEnd()
    // restore the model view matrix to prevent contamination
    GL11.glPopMatrix()
  }
```

I needed to load sprites to be painted by the function above, apparently the only thing needed to reference the loaded 
texture is it's id.

The `TextureLoader` is based on the code from [this post](http://stackoverflow.com/a/10872080/817620) and converted to 
scala.

The process behind the `TextureLoader` is to load the file using Java's `ImageIO`,

```scala
def newTexture(path: String): Try[Texture] = {
  Try {
    try {
      Option(getClass.getClassLoader.getResourceAsStream(path)).map { inputStream =>
        loadOpenGL(ImageIO.read(inputStream))
      }
        .getOrElse(throw new NullPointerException(s"Cannot load input stream on path $path"))
    }
  }
}
```
    
convert that to the byte information and pass it to OpenGL, getting only an integer id back using `glTexImage2D`.

```scala

case class Texture(id: Int, width: Int, height: Int)

private[this] def loadOpenGL(image: BufferedImage): Texture = {
  val pixels = new Array[Int](image.getWidth * image.getHeight)
  image.getRGB(0, 0, image.getWidth, image.getHeight, pixels, 0, image.getWidth)
  val buffer = BufferUtils.createByteBuffer(image.getWidth * image.getHeight * BYTES_PER_PIXEL)
  //4 for RGBA, 3 for RGB
  
  for(y <- 0 until image.getHeight; x <- 0 until image.getWidth) {
    val pixel = pixels(y * image.getWidth + x)
    buffer.put(((pixel >> 16) & 0xFF).toByte) // Red component
    buffer.put(((pixel >> 8) & 0xFF).toByte) // Green component
    buffer.put((pixel & 0xFF).toByte) // Blue component
    buffer.put(((pixel >> 24) & 0xFF).toByte) // Alpha component. Only for RGBA
  }
  buffer.flip //FOR THE LOVE OF GOD DO NOT FORGET THIS
  
  // You now have a ByteBuffer filled with the color data of each pixel.
  // Now just create a texture ID and bind it. Then you can newTexture it using
  // whatever OpenGL method you want, for example:
  val textureID = GL11.glGenTextures //Generate texture ID
  GL11.glBindTexture(GL11.GL_TEXTURE_2D, textureID) //Bind texture ID
  
  //Setup wrap mode
  GL11.glTexParameteri(GL11.GL_TEXTURE_2D, GL11.GL_TEXTURE_WRAP_S, GL12.GL_CLAMP_TO_EDGE)
  GL11.glTexParameteri(GL11.GL_TEXTURE_2D, GL11.GL_TEXTURE_WRAP_T, GL12.GL_CLAMP_TO_EDGE)
  //Setup texture scaling filtering
  GL11.glTexParameteri(GL11.GL_TEXTURE_2D, GL11.GL_TEXTURE_MIN_FILTER, GL11.GL_LINEAR)
  GL11.glTexParameteri(GL11.GL_TEXTURE_2D, GL11.GL_TEXTURE_MAG_FILTER, GL11.GL_LINEAR)
  //Send texel data to OpenGL
  GL11.glTexImage2D(GL11.GL_TEXTURE_2D, 0, GL11.GL_RGBA8, image.getWidth, image.getHeight, 0, GL11.GL_RGBA, GL11.GL_UNSIGNED_BYTE, buffer)
  
  //Return the texture ID so we can bind it later again
  Texture(textureID, image.getHeight, image.getWidth)
}
```

As you can see I wrap the textureId along with the width and height, I might be useful later.

The last touches to paint the image are to load the image before entering the loop 
```scala
TextureLoader.newTexture("mario.png") map { texture =>
```

and draw inside of the loop

``` scala
while ( {
    !glfwWindowShouldClose(window)
  }) {
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT) // clear the framebuffer

    draw(texture, 0, 0)
    glfwSwapBuffers(window) // swap the color buffers

    // Poll for window events. The key callback above will only be
    // invoked during this call.
    glfwPollEvents()
  }
```

<img src="/images/posts/game-engine/screenshot1.png" alt="First game screenshot" class="img-50" />

What is going on here? I'm obviously doing something wrong, but at this stage I have no clue of what it is. Will come 
back to it later.  

To be continued...

You can see the sources for this project on <https://github.com/adrijardi/right-miner>
