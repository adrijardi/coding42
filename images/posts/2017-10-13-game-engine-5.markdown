---
title: Functional Game engine in Scala, Part 5
---

## We want to have more colliders: Box collider

The current implementation of colliders works fine for a small number of them but it will get
cumbersome when adding new ones pretty soon.

```scala
case class BoxCollider(ref: ComponentRef, gameObjectRef: GameObjectRef, relativePosition: Position, size: Position, trigger: Boolean) extends Collider
```

I decided to separate the drawing and colliding logic on separate classes, instead of leaving
the functionality on the case classes. For that reason we have now the `Drawable` object.

```scala
package com.coding42.engine

import org.lwjgl.opengl.GL11
import GL11._

trait Drawable[T <: Component] {
  def draw(t: T)(world: World): Unit
}

object Drawable {

  def draw(t: Component)(world: World): Unit = t match {
    case c: SpriteRenderer  => SpriteDrawable.draw(c)(world)
    case c: SphereCollider  => SphereColliderDrawable.draw(c)(world)
    case c: BoxCollider     => BoxColliderDrawable.draw(c)(world)
    case _: CodeLogic       =>
  }

  object SpriteDrawable extends Drawable[SpriteRenderer] {

    override def draw(t: SpriteRenderer)(world: World): Unit = {

      val position = t.gameObject(world).transform.position
      val scale = t.gameObject(world).transform.scale

      glBindTexture(GL_TEXTURE_2D, t.texture.id)

      // store the current model matrix
      glPushMatrix()
      // translate to the right location and prepare to draw
      glTranslatef(position.x, position.z, 0)
      // draw a quad textured to match the sprite
      glBegin(GL_QUADS)

      glTexCoord2f(0, 0)
      glVertex2f(0, 0)

      glTexCoord2f(0, 1)
      glVertex2f(0, scale.z)

      glTexCoord2f(1, 1)
      glVertex2f(scale.x, scale.z)

      glTexCoord2f(1, 0)
      glVertex2f(scale.x, 0)

      glEnd()
      // restore the model view matrix to prevent contamination
      glPopMatrix()
    }
  }

  object BoxColliderDrawable extends Drawable[BoxCollider] {

    override def draw(t: BoxCollider)(world: World): Unit =
      if(world.gameConfig.debug) {
        val position = t.gameObject(world).transform.position + t.relativePosition

        glLineWidth(4f)

        glBegin(GL_LINE_LOOP)
        glVertex3f(position.x, position.z, 0f)
        glVertex3f(position.x + t.size.x, position.z, 0f)
        glVertex3f(position.x + t.size.x, position.z + t.size.z, 0f)
        glVertex3f(position.x, position.z + t.size.z, 0f)
        glEnd()
      }
    }

  object SphereColliderDrawable extends Drawable[SphereCollider] {

    override def draw(t: SphereCollider)(world: World): Unit =
      if(world.gameConfig.debug) {
        val position = t.gameObject(world).transform.position

        glLineWidth(4f)

        glBegin(GL_LINE_LOOP)
        glVertex3f(position.x - t.radius, position.z, 0f)
        glVertex3f(position.x, position.z - t.radius, 0f)
        glVertex3f(position.x + t.radius, position.z, 0f)
        glVertex3f(position.x, position.z + t.radius, 0f)
        glEnd()
      }
  }

}
```

Same thing with the collision calculation, the `CollisionChecker` trait doesn't play any role
right now, it might come handy later.

It is particularly interesting the code to detect if there was any collision, particularly between
box and sphere.

```scala
trait CollisionChecker[A <: Collider, B <: Collider] {
  def hasCollision(a: A, b: B)(world: World): Boolean
}

object CollisionChecker {

  object SphereSphereCollisionChecker extends CollisionChecker[SphereCollider, SphereCollider] {
    override def hasCollision(a: SphereCollider, b: SphereCollider)(world: World): Boolean = {
      val distance = Position.distance(a.position(world), b.position(world))
      distance < a.radius + b.radius
    }
  }

  object SphereBoxCollisionChecker extends CollisionChecker[SphereCollider, BoxCollider] {
    override def hasCollision(sphere: SphereCollider, box: BoxCollider)(world: World): Boolean = {
      var dmin = 0f

      val center = sphere.position(world)
      val bmin = box.position(world)
      val bmax = box.position(world) + box.size

      if (center.x < bmin.x) {
        dmin += Math.pow(center.x - bmin.x, 2).toFloat
      } else if (center.x > bmax.x) {
        dmin += Math.pow(center.x - bmax.x, 2).toFloat
      }

      if (center.y < bmin.y) {
        dmin += Math.pow(center.y - bmin.y, 2).toFloat
      } else if (center.y > bmax.y) {
        dmin += Math.pow(center.y - bmax.y, 2).toFloat
      }

      if (center.z < bmin.z) {
        dmin += Math.pow(center.z - bmin.z, 2).toFloat
      } else if (center.z > bmax.z) {
        dmin += Math.pow(center.z - bmax.z, 2).toFloat
      }

      dmin <= Math.pow(sphere.radius, 2)
    }
  }

  object BoxBoxCollisionChecker extends CollisionChecker[BoxCollider, BoxCollider] {
    override def hasCollision(a: BoxCollider, b: BoxCollider)(world: World): Boolean = {
      val posA = a.position(world)
      val posB = b.position(world)

      (isBetween(posA.x, posB.x, posB.x + b.size.x) || isBetween(posA.x + a.size.x, posB.x, posB.x + b.size.x)) &&
      (isBetween(posA.y, posB.y, posB.y + b.size.y) || isBetween(posA.y + a.size.y, posB.y, posB.y + b.size.y)) &&
      (isBetween(posA.z, posB.z, posB.z + b.size.z) || isBetween(posA.z + a.size.z, posB.z, posB.z + b.size.z))
    }
  }

  def hasCollision(a: Collider, b: Collider)(world: World): Boolean = {
    (a,b) match { // TODO horrible
      case (b1: SphereCollider, b2: SphereCollider) => SphereSphereCollisionChecker.hasCollision(b1, b2)(world: World)
      case (b1: BoxCollider, b2: BoxCollider) => BoxBoxCollisionChecker.hasCollision(b1, b2)(world: World)
      case (b1: SphereCollider, b2: BoxCollider) => SphereBoxCollisionChecker.hasCollision(b1, b2)(world: World)
      case (b1: BoxCollider, b2: SphereCollider) => SphereBoxCollisionChecker.hasCollision(b2, b1)(world: World)
    }
  }
}
```


And we now got a new type of collider

<img src="/images/posts/game-engine/box-collider.png" alt="Box collider" class="img-50" />

You can see the sources for this project on <https://github.com/adrijardi/right-miner>
