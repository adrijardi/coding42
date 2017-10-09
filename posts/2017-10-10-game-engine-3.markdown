---
title: Functional Game engine in Scala, Part 3
---

## Move it Mario!
The current key handling wasn't cut it. It just moved Mario 1 pixel per key press and I needed him to move continuously 
while pressed. For this the component will have to be kept immutable and therefore it has to return a modified `World`,
the `CodeLogic` trait will work perfectly. This would be the implementation of the `Player`:

```scala
object Player {

  case class PlayerMovement(ref: ComponentRef, gameObjectRef: GameObjectRef, xMov: Int, zMov: Int) extends CodeLogic {

    val speed = 30f

    override def handleKeyDown(key: Int)(world: World): World = {
      key match {
        case GLFW_KEY_D => world.withComponent(copy(xMov = 1))
        case GLFW_KEY_A => world.withComponent(copy(xMov = -1))
        case GLFW_KEY_S => world.withComponent(copy(zMov = 1))
        case GLFW_KEY_W => world.withComponent(copy(zMov = -1))
        case _ => world
      }
    }

    override def handleKeyUp(key: Int)(world: World): World = {
      (key, xMov, zMov) match {
        case (GLFW_KEY_D, 1, _) => world.withComponent(copy(xMov = 0))
        case (GLFW_KEY_A, -1, _) => world.withComponent(copy(xMov = 0))
        case (GLFW_KEY_S, _, 1) => world.withComponent(copy(zMov = 0))
        case (GLFW_KEY_W, _, -1) => world.withComponent(copy(zMov = 0))
        case _ => world
      }
    }

    override def onUpdate(deltaTime: Float)(world: World): World = {
      val go = gameObject(world)
      val position = go.transform.position

      def mov(axisMov: Int) = {
        axisMov match {
          case x if x < 0 => speed * deltaTime * -1
          case x if x > 0 => speed * deltaTime
          case _ => 0f
        }
      }

      val newPos = position.copy(x = position.x + mov(xMov), z = position.z + mov(zMov))
      world.withGameObject(go.withPos(newPos))
    }

  }

  def apply(resources: Resources): Entity = {
    val player = GameObject("player", Transform(Position.zero, Scale(16, 1, 30)))

    val components = Set[Component]( // TODO why this?
      SpriteRenderer(player.ref, resources.player),
      PlayerMovement(ComponentRef(), player.ref, 0, 0),
      SphereCollider(player.ref, Position.zero, 20, trigger = true)
    )

    (player, components)
  }

}
```

Additionally we need to create the `EntityLoader` that will create the Player in the world:

```scala
object MinerEntitiesLoader extends EntitiesLoader[Resources] {

  override def apply(resources: Resources): Set[(GameObject, Set[Component])] =
    Set(GameManager(resources), Player(resources))

}
```

And the Boot class that will use that loader:

```scala
object Boot extends Booter(GameConfig(300, 300, "Right miner!"), MinerResourceLoader, MinerEntitiesLoader) with App {
  run()
}
```

## Let's give Mario a friend
A brick block would be the best friend for Mario

```scala
object Block {

  def apply(resources: Resources): Entity = {
    val block = GameObject("block", Transform(Position(100, 0, 100), Scale(16, 1, 30)))

    val components = Set[Component](
      SpriteRenderer(block.ref, resources.block),
      SphereCollider(block.ref, Position.zero, 20, trigger = true)
    )

    (block, components)
  }

}
```

As you can see we are adding a collider to the brick, that will make things more interesting.
Here is the implementation of a very simple sphere collider:

```scala
sealed trait Collider extends Component {

  def relativePosition: Position

  def trigger: Boolean

  def position(world: World): Position = gameObject(world).transform.position + relativePosition
}

object Collider {

  def hasCollision(a: Collider, b: Collider)(world: World): Boolean = {
    (a,b) match {
      case (b1:SphereCollider, b2:SphereCollider) => hasCollision(b1, b2)(world: World)
    }
  }

  def hasCollision(a: SphereCollider, b: SphereCollider)(world: World): Boolean = {
    Position.distance(a.position(world), b.position(world)) < a.radius + b.radius
  }

  def collisions(c: Iterable[Collider])(world: World): Map[GameObjectRef, Set[Collision]] = {
    import cats.Semigroup
    import cats.implicits._
    val semigroup = Semigroup[Map[GameObjectRef, Set[Collision]]] // TODO check this works fine, maybe a little test ;)
    c match {
      case Nil => Map.empty
      case h :: t => semigroup.combine(collisions(h, t)(world), collisions(t)(world))
    }
  }

  private def collisions(c: Collider, iterable: Iterable[Collider])(world: World): Map[GameObjectRef, Set[Collision]] = {
    iterable.collect {
      case o if hasCollision(c, o)(world) =>
        Map(c.gameObjectRef -> Set(Collision(o)), o.gameObjectRef -> Set(Collision(c)))
    }.fold(Map.empty)(_ ++ _)
  }

}

case class SphereCollider(ref: ComponentRef, gameObjectRef: GameObjectRef, relativePosition: Position, radius: Float, trigger: Boolean) extends Collider

object SphereCollider {

  def apply(gameObjectRef: GameObjectRef, relativePosition: Position, radius: Float, trigger: Boolean): SphereCollider = {
    new SphereCollider(ComponentRef(), gameObjectRef, relativePosition, radius, trigger)
  }

}
```

And of course we need to do something with Mario when it touches the collider, let's just change his position:

```scala
override def onCollisionEnter(collision: Collision)(world: World): World = {
  val go = gameObject(world)
  world.withGameObject(go.withPos(Position.zero))
}
```

<img src="/images/posts/game-engine/with-block.png" alt="Mario has a friend" class="img-50" />

You can see the sources for this project on https://github.com/adrijardi/right-miner
