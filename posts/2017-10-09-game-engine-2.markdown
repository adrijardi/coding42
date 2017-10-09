---
title: Functional Game engine in Scala, Part 2
---

## Move Mario around
The example code already provides some key handling, let's extend it and
move Mario around the screen.
To make it easy for now I add some mutable variables, additional cases to
the function sent to `glfwSetKeyCallback` and use those variables on the
call to the drawing method.

``` scala
...

var posX = 0
var posY = 0

private def init() = {
...
```

``` scala
    // Setup a key callback. It will be called every time a key is pressed, repeated or released.
    glfwSetKeyCallback(window, (window: Long, key: Int, scancode: Int, action: Int, mods: Int) => {
      def foo(window: Long, key: Int, scancode: Int, action: Int, mods: Int) = {
        if (key == GLFW_KEY_ESCAPE && action == GLFW_RELEASE) glfwSetWindowShouldClose(window, true) // We will detect this in the rendering loop
        if (key == GLFW_KEY_D) posX += 1
        if (key == GLFW_KEY_A) posX -= 1
        if (key == GLFW_KEY_S) posY += 1
        if (key == GLFW_KEY_W) posY -= 1
      }

      foo(window, key, scancode, action, mods)
    })
```

``` scala
while ( {
    !glfwWindowShouldClose(window)
  }) {
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT) // clear the framebuffer

    draw(texture, posX, posYx   x)
    glfwSwapBuffers(window) // swap the color buffers

    // Poll for window events. The key callback above will only be
    // invoked during this call.
    glfwPollEvents()
  }
```

<img src="/images/posts/game-engine/mario-moving.png" alt="Mario moving" class="img-50" />

The broken texture is really bugging me, but I want to keep working on
interesting stuff.

## Get the engine out
Next, I want to start separating the engine into different packages
(I'm still on the plane and I don't remember how to configure SBT submodules).

The engine will deal with everything low level, like initialization of
the OpenGL infrastructure, create the resources, key handling and the game loop.

The game will provide a the definition of the resources to load, the
game objects to create and some basic configuration.

This is the game object

```scala
case class GameObject(ref: GameObjectRef, transform: Transform) {
  def withPos(position: Position): GameObject = copy(transform = transform.copy(position = position))
}

object GameObject {

  def apply(transform: Transform): GameObject = {
    new GameObject(GameObjectRef(), transform)
  }

}
```

Some simple helper classes:

```scala
case class Transform(position: Position)

case class Position(x: Float, y: Float, z: Float)

case class GameConfig(screenWidth: Int, screenHeight: Int)
```

I needed a way to reference the object when changing:

```scala
case class GameObjectRef(ref: Int)

object GameObjectRef {

  private[this] val counter: AtomicInteger = new AtomicInteger(0)

  // TODO force calling this
  def apply(): GameObjectRef = {
    new GameObjectRef(counter.incrementAndGet())
  }
}
```

Components definition:
```scala
sealed trait Component {
  def gameObjectRef: GameObjectRef
  def gameObject(world: World): GameObject = world.gameObjects(gameObjectRef) // TODO this might blow up when deleting GOs
}

case class SpriteRenderer(gameObjectRef: GameObjectRef, texture: Texture) extends Component {

  def draw(world: World): Unit = {

    val position = gameObject(world).transform.position

    GL11.glBindTexture(GL11.GL_TEXTURE_2D, texture.id)

    // store the current model matrix
    GL11.glPushMatrix()
    // bind to the appropriate texture for this sprite
    //    texture.bind
    // translate to the right location and prepare to draw
    GL11.glTranslatef(position.x, position.z, 0)
    GL11.glColor3f(1, 1, 1)
    // draw a quad textured to match the sprite
    GL11.glBegin(GL11.GL_QUADS)
    GL11.glTexCoord2f(0, 0)
    GL11.glVertex2f(0, 0)
    GL11.glTexCoord2f(0, texture.height)
    GL11.glVertex2f(0, world.gameConfig.screenHeight)
    GL11.glTexCoord2f(texture.width, texture.height)
    GL11.glVertex2f(world.gameConfig.screenWidth, world.gameConfig.screenHeight)
    GL11.glTexCoord2f(texture.width, 0)
    GL11.glVertex2f(world.gameConfig.screenWidth, 0)

    GL11.glEnd()
    // restore the model view matrix to prevent contamination
    GL11.glPopMatrix()
  }

}

trait CodeLogic extends Component {
  def handleKeyDown(key: Int)(world: World): World = world
  def handleKeyUp(key: Int)(world: World): World = world
  def handleKeyPressed(key: Int)(world: World): World = world
}

```

The idea would be to maintain a world object that is passed to all components
they will be able to return a modified version which will be passed along.

```scala
case class World(gameObjects: Map[GameObjectRef, GameObject], components: Map[GameObjectRef, Set[Component]], gameConfig: GameConfig) {

  def withGameObject(gameObject: GameObject): World = {
    copy(gameObjects = gameObjects.updated(gameObject.ref, gameObject))
  }

  def withComponent(component: Component): World = {
    val prevGoComponents = components.getOrElse(component.gameObjectRef, Set.empty)
    val newComponents = components + (component.gameObjectRef -> (prevGoComponents + component))
    copy(components = newComponents)
  }

  def allComponents: Iterable[Component] = components.values.flatten

}

object World {

  def empty(gameConfig: GameConfig): World = new World(Map.empty, Map.empty, gameConfig)

}
```

The engine logic is separated on Boot and moved into another class
which calls the sprite components to draw

```scala
class Booter(config: GameConfig, resourceLoader: ResourceLoader, entitiesLoader: EntitiesLoader) {
  private var window = 0L
  private var world: World = World.empty(config)

  def run(): Unit = {
    System.out.println("Hello LWJGL " + Version.getVersion + "!")
    init()
    loop()
    // Free the window callbacks and destroy the window
    glfwFreeCallbacks(window)
    glfwDestroyWindow(window)
    // Terminate GLFW and free the error callback
    glfwTerminate()
    glfwSetErrorCallback(null).free()
  }

  private def init() = { // Setup an error callback. The default implementation
    // will print the error message in System.err.
    GLFWErrorCallback.createPrint(System.err).set
    // Initialize GLFW. Most GLFW functions will not work before doing this.
    if (!glfwInit) throw new IllegalStateException("Unable to initialize GLFW")
    // Configure GLFW
    glfwDefaultWindowHints() // optional, the current window hints are already the default

    glfwWindowHint(GLFW_VISIBLE, GLFW_FALSE) // the window will stay hidden after creation

    glfwWindowHint(GLFW_RESIZABLE, GLFW_TRUE) // the window will be resizable

    // Create the window
    val config = world.gameConfig
    window = glfwCreateWindow(config.screenWidth, config.screenHeight, "Hello World!", NULL, NULL)
    if (window == NULL) throw new RuntimeException("Failed to create the GLFW window")

    // Setup a key callback. It will be called every time a key is pressed, repeated or released.
    glfwSetKeyCallback(window, (window: Long, key: Int, scancode: Int, action: Int, mods: Int) => {
      def foo(window: Long, key: Int, scancode: Int, action: Int, mods: Int) = {
        if (key == GLFW_KEY_ESCAPE && action == GLFW_RELEASE) glfwSetWindowShouldClose(window, true) // We will detect this in the rendering loop
        if (action == GLFW_PRESS) {
          world = world.allComponents.collect {
            case c: CodeLogic => c
          }.foldLeft(world)( (w, l) => l.handleKeyPressed(key)(w)) // TODO change to traverse ?
        }
      }

      foo(window, key, scancode, action, mods)
    })
    // Get the thread stack and push a new frame
    try {
      val stack = stackPush
      try {
        val pWidth = stack.mallocInt(1)
        // int*
        val pHeight = stack.mallocInt(1)
        // Get the window size passed to glfwCreateWindow
        glfwGetWindowSize(window, pWidth, pHeight)
        // Get the resolution of the primary monitor
        val vidmode = glfwGetVideoMode(glfwGetPrimaryMonitor)
        // Center the window
        glfwSetWindowPos(window, (vidmode.width - pWidth.get(0)) / 2, (vidmode.height - pHeight.get(0)) / 2)
        // the stack frame is popped automatically} finally {
        if (stack != null) stack.close()
      }
    }
    // Make the OpenGL context current
    glfwMakeContextCurrent(window)
    // Enable v-sync
    glfwSwapInterval(1)
    // Make the window visible
    glfwShowWindow(window)
  }

  private def loop() = { // This line is critical for LWJGL's interoperation with GLFW's
    // OpenGL context, or any context that is managed externally.
    // LWJGL detects the context that is current in the current thread,
    // creates the GLCapabilities instance and makes the OpenGL
    // bindings available for use.
    GL.createCapabilities

    // enable textures since we're going to use these for our sprites// enable textures since we're going to use these for our sprites
    GL11.glEnable(GL11.GL_TEXTURE_2D)

    // disable the OpenGL depth test since we're rendering 2D graphics
    GL11.glDisable(GL11.GL_DEPTH_TEST)

    GL11.glMatrixMode(GL11.GL_PROJECTION)
    GL11.glLoadIdentity()

    val config = world.gameConfig
    GL11.glOrtho(0, config.screenWidth, config.screenHeight, 0, -1, 1)

    // Set the clear color
    glClearColor(.3f, 0.8f, 0.3f, 0.0f)

    resourceLoader() match {
      case Success(resources) =>

        val entities = entitiesLoader(resources).unzip
        val gameObjects = entities._1
        val components = entities._2.flatten
        world = components.foldLeft(world)( (worldRes, c) => worldRes.withComponent(c) )

        world = gameObjects.foldLeft(world)( (worldRes, go) => worldRes.withGameObject(go) )

        // Run the rendering loop until the user has attempted to close
        // the window or has pressed the ESCAPE key.
        while ( {
          !glfwWindowShouldClose(window)
        }) {
          glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT) // clear the framebuffer

          world.allComponents.foreach {
            case c: SpriteRenderer => c.draw(world)
            case _ => ()
          }

          glfwSwapBuffers(window) // swap the color buffers

          // Poll for window events. The key callback above will only be
          // invoked during this call.
          glfwPollEvents()
        }

      case Failure(NonFatal(t)) =>
        System.err.println(s"Could not load resources, cause: $t")
    }
  }

}
```

## Fix the texture
I went through the texture loader and the sprite drawer. The issue was on the Sprite drawer, it used pixel values for 
the texture coordinate when it had to use range from 0 to 1. Piece of cake.

Next time we will improve the movement and add more components to the game

You can see the sources for this project on <https://github.com/adrijardi/right-miner>
