---
title: Functional Game engine in Scala, Part 4
---

## Debug Information

I have noticed that the colliders seem to be a bit off. It would be nice to be able to render
some debug information on all components.

As it is now we only try to draw `SpriteRenderer` components, we can have a `draw` function on all
components and then let them decide whether something is drawn or not.

`Component` will implement a default draw method

```scala
protected[engine] def draw(world: World): Unit = ()
```

implemented for `SphereCollider` like this

```scala
override protected[engine] def draw(world: World): Unit =
    if(world.gameConfig.debug) {
      val position = gameObject(world).transform.position

      import GL11._

      glLineWidth(4f)

      glBegin(GL_LINE_LOOP)
      glVertex3f(position.x - radius, position.z, 0f)
      glVertex3f(position.x, position.z - radius, 0f)
      glVertex3f(position.x + radius, position.z, 0f)
      glVertex3f(position.x, position.z + radius, 0f)
      glEnd()
    }
```

<img src="/images/posts/game-engine/debug-collisions.png" alt="We can see collision 'kind of spheres'" class="img-50" />

I could find that there was a bug on the code to calculate the distance between two positions,
here the fixed code:

```scala
object Position {

  val zero: Position = Position(0,0,0)

  def distance(a: Position, b: Position): Float = {
    import Math._
    val x = pow(a.x - b.x, 2)
    val y = pow(a.y - b.y, 2)
    val z = pow(a.z - b.z, 2)
    sqrt(x + y + z).toFloat
  }

}
```

You can see the sources for this project on <https://github.com/adrijardi/right-miner>
