---
title: Functional programming with Scala, Part 1
---

    val list = [1, 5, 12 ,6]


    var sum = 0
    for(num <- list) yield sum += num


    list.foldLeft(0)(_ + _)


    list.fold(0)(_ + _)


### Additional benefits
- No need to write defensive code when writing or invoking functions,
immutable collections cannot be modified without side effects on any other
part of the system that uses them
- The fold reduce operation can could be paralelised to benefit from multicore machines or even distributed processing