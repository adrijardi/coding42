---
title: Getting started with Functional Programming
---

Functional programming is not about learning an specific programming language, it's a paradigm and, whilst it's true that you will require
your language of choice to provide you with certain tools, nowadays most languages can be considered functional to one or another degree.

## But, what does functional mean?

There are many opinions when it comes to what makes a language functional, and as always it's not a black or white distinction. The main
requisites are that computations are treated as mathematical functions where it receives some parameters and returns a result after the
computation which in turn implies that the data would be immutable. But when you think about it most languages allow it in one way or
another. As an example, you could potentially do functional programming with early versions of Java as long as your functions didn't
performed side effects and only returned values. Of course the language would not playing in your favour by not making your job easier
with the adequate constructs or syntactic sugar but it would be technically possible.

If we taken a wider view of what functional means we find language features like closure, currying, immutability, data classes, etc. Which
all will help to create more concise code.

## So, what benefits does it bring?

FP generally allows to develop software in a more idiomatic and concise manner translating to less code which usually
means less bugs and less maintainability costs. Also, when using inmutable objects you can reason much easier about the code behaviour as
you don't have to worry about side effects. But this doesn't mean FP is a silver bullet and should be used always over an imperative
paradigm, mainly because FP is hard, it requires more effort from the programmer, both on design and on implementation to create a fine
solution to a problem.
Also inmutable objects are not fit for all problems, certain algorithms will have a much larger memory footprint or even higher cost in CPU
if performed using inmutability. And even worse, algorithms can become much more complicated than their mutable counterparts when they are
tailored for inmutability.
As I like to say, use the best tool for every job, there is nothing to win from "functional purity" if it's at the cost of complexity.

## Do I need to learn category theory?
No.

## Would I at least benefit from learning it?

It depends on what you work on. If you are planning on creating an application regardless of it's complexity you won't need it. If you, on
the other hand strive to create super elegant code you can find a lot of pleasure on it. But I'd say that knowing category theory would only
be really required if you plan working on libraries that implement those concepts like Scalaz or Cats.

## Why do you do FP?

Because I like it. I come from a Java background and I got very exited when then released generics and the possibilities they opened to me.
Regardless of that, I always found Java to restricted and often found myself limited by the language in one way or another, especially when
it came to type safety.
Some time ago I made the jump to Scala and I found it over complicated and very hard to read or reason about but I slowly came to realise
the benefits when it comes to concurrency and implementation of complex business logic. Also playing with Scala I continuously find new
features and approaches to old problems.

