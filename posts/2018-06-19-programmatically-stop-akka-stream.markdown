---
title: Programmatically Stop Akka Streams
---

In certain situations we require to stop a reactive stream based on internal
or external system conditions. By just using the standard graph components
is not possible to configure the stream in this way, but fortunately Akka
provides with the GraphStage mechanism to create custom graphs.

As can be seen on the following snippet the code consists on defining the
input and output and then override the internal logic overriding `createLogic`.
As the goal of this flow is to interrupt the processing of messages based
on the condition passed as parameter `createLogic` extends `TimerGraphLogic`,
which allows to check the condition using a scheduler. The relevant parts
are the following:

- onPush handler: Event received when the upstream pushes new elements.
We didn't want to stop the flow when handling the push event as the messages
are read from a SQS queue and therefore if they are left unprocessed for
a long time they will become available to read again. For this reason we
focus on interrupting the flow using `pull`.

- onPull handler: Event received when the downstream requests new elements.
The condition is checked and when satisfied messages are pulled from the upstream
(in our case it will trigger reading an event from SQS), in the negative
case the scheduler is set to trigger after a timeout. It is important to
note that when the downstream has pulled it will not `pull` again until
an element is pushed.

- onTimer: It is called when any scheduled timer expires. When a pull is
not performed because the condition was not met the scheduler is set to
check again after the timer expires and keep checking until the condition
is met.

```scala
class ConditionChecker[A](condition: () => Boolean) extends GraphStage[FlowShape[A, A]] {

  val in = Inlet[A]("Filter.in")
  val out = Outlet[A]("Filter.out")

  val shape = FlowShape.of(in, out)

  override def createLogic(inheritedAttributes: Attributes): GraphStageLogic =
    new TimerGraphStageLogic(shape) {
      setHandler(in, new InHandler {
        override def onPush(): Unit = {
          push(out, grab(in))
        }
      })
      setHandler(out, new OutHandler {
        override def onPull(): Unit = {
          if(condition()) {
            pull(in)
          } else {
            scheduleOnce(None, 2 seconds)
          }
        }
      })

      override protected def onTimer(timerKey: Any): Unit = {
        if(condition())
          pull(in)
        else
          scheduleOnce(None, 2 seconds)
      }
    }
}
```

Here is some crude support code that was used to run the previous code and
check it's behaviour:

```scala
object GraphTest extends App {

  implicit val system = ActorSystem("test-system", ConfigFactory.load("application-test"))
  implicit val mat = ActorMaterializer()

  def stream(start: Int): Stream[Int] = {
    Stream.cons(start, {
      println(s"Generated $start")
      stream(start+1)
    })
  }

  Source.fromIterator(() => stream(1).toIterator)
    .via(new ConditionChecker[Int](() => checkPrice))
    .map(a => {
      Thread.sleep(1000)
      a
    })
    .runForeach(r => println(s"Sink: $r"))

  var run = true

  def reverseAfter5Sec: Unit = {
    Future {
      Thread.sleep(5)
      run = !run
    }.onComplete(_ => reverseAfter5Sec)
  }

  reverseAfter5Sec

  def checkPrice: Boolean = {
    println(s"Returned $run")
    run
  }
}
```

This implementation is based on the amazing [Akka documentation](https://doc.akka.io/docs/akka/current/stream/stream-customize.html),
if you enjoyed the article you should take a look to the very useful examples there.