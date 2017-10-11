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

<img src="/images/posts/game-engine/debug-collisions.png" alt="Mario moving" class="img-50" />

You can see the sources for this project on [https://github.com/adrijardi/right-miner]
