---
title: Functional Game engine in Scala, Part 5
---

## We want to have more colliders: Box collider

The current implementation of colliders works fine for a small number of them but it will get
cumbersome when adding new ones pretty soon. Also following the spirit of the project it would
be nice to have a more type safe solution. To address this, the checks for collisions will
be implemented using type classes and the `Iterator[Collider]` will be replaced with `HList` from
[Shapeless](some.link) to keep the types around.

## Nicer background and camera controls

The green background has served us well, but it is time to move on and find something more
appropriate to the theme.

<img>

At this point we would like for the camera to follow Mario. Let's add support for a main camera
to the engine and allow to program it with `CodeLogic` components.

The camera now follows mario around the map!
