---
title: Getting started with Functional Programming
---

Functional programming (FP) is not about learning an specific programming language, it's a paradigm and, whilst it's true that it will help
you using a language that provides certain tools, nowadays most languages can allow functional programming to one or another degree.

## But, what does functional programming mean?

The main requisite for functional programming is that computations are treated as mathematical functions which means that they receive
some parameters and return a result based solely on them. This implies that the data would be immutable and that these functions
would not store an internal state. This is, of course, not the end of it; if we take a wider view of what functional means we find language
features like higher order functions, closures, currying, immutability, data classes and so on, which all will help to create more concise code.

This approach contrasts a lot with the imperative paradigm which most people are familiar with and that is featured in all "C like" languages.
In FP operations are usually defined as combinations of functions (and higher order functions) to achieve transformations while in C transformations
would be applied directly over the data one after another to provide an output.

Regarding the question of what languages allow to do FP, you should notice that the requirements from the language itself are quite basic and
most languages will allow you to write code on a functional way, but of course some of them are more oriented in this way and will provide more
tools to do it efficiently.

## So, what benefits does it bring?

Functional programming generally allows to develop software in a more idiomatic and concise manner, translating to less code which normally
means less bugs and less maintainability costs. Also, when using immutability you can reason much easier about the code's behaviour as
you don't have to worry about side effects. This however, doesn't mean functional programming is a silver bullet and should be used always
over an imperative paradigm, mainly because FP is hard, it requires more effort from the programmer, both on design and implementation
to create a fine solution to a problem.

Also immutable objects are not good fit for all problems, as certain algorithms will have a much larger memory footprint or even higher cost
in CPU when using immutable data structures. And even worse, algorithms can become much more complicated than their mutable counterparts
when they are tailored for immutability.

As they say, use the best tool for every job. There is nothing to win from "functional purity" if it's at the cost of complexity.

## Do I need to learn category theory? What is a monad?
No, don't get started in FP by learning the theory, get your hands dirty. Also don't try to learn what a monad (or any other concept) is from definitions, use
the language and it's features, use FP libraries and get familiar with them. After a while you will realise that you have been using this concepts
for a while and that they are not something so exotic.

Once you are familiar with the paradigm you might benefit from category theory, but it will depend on what you work on. If you are planning
on creating an application, regardless of it's complexity you won't need it. If you, on
the other hand strive to create really elegant code you could find a lot of pleasure on it. But I'd say that knowing category theory would only
be really necessary when planning on working on libraries that implement those concepts like Scalaz or Cats.

## Why do you do functional programming?

Because I like it. I come from a Java background and I got very excited when generics were released because the possibilities they opened to me.
Regardless of that, I always found Java too restricted and often found myself limited by the language in one way or another, especially when
it came to type safety. Also I did actually start doing functional programming in Java without actually realising what I was doing.

Some time ago I made the jump to Scala and I found it over complicated and very hard to read, write and reason about but I slowly realised
the benefits it brought when it comes to concurrency and implementation of complex business logic. Also playing with Scala I keep
continuously finding new features and approaches to old problems and this keeps me entertained and engaged at work which I love.
