---
title: "Understanding the CAP Theorem"
slug: "understanding-the-cap-theorem"
tags: ['cap-theorem', 'distributed-systems']
date: 2017-12-20T22:21:06+08:00
---

## Background

The CAP theorem has become one of the hottest theorems in recent years; when discussing distributed systems, CAP is inevitably mentioned. However, I feel that I haven't thoroughly understood it, so I wanted to write a blog post to record my understanding. I will update the content as I gain new insights.

## Understanding

I read the first part of this [paper](https://static.googleusercontent.com/media/research.google.com/zh-CN//pubs/archive/45855.pdf).

> The CAP theorem [Bre12] says that you can only have two of the three desirable properties of:
>
> * C: Consistency, which we can think of as serializability for this discussion;
> * A: 100% availability, for both reads and updates;
> * P: tolerance to network partitions.
>
> This leads to three kinds of systems: CA, CP and AP, based on what letter you leave out.

Let me share my understanding, using a network composed of three machines (x, y, and z) as an example:

* **C (Consistency)**: The three machines appear as one. Operations of addition, deletion, modification, and query on any one machine should always be consistent. That is, if you read data from x and then read from y, the results are the same. If you write data to x and then read from y, you should also read the newly written data. Wikipedia also specifically mentions that it's acceptable to read the data just written to x from y after a short period of time (eventual consistency).

* **A (Availability)**: The three machines, as a whole, must always be readable and writable; even if some parts fail, it must be readable and writable.

* **P (Partition Tolerance)**: If the network between x, y, and z is broken, any machine cannot or refuses to provide services; it is neither readable nor writable.

Here, **C** is the easiest to understand. The concepts of **A** and **P** are somewhat vague and easy to confuse.

Now let's discuss the three combinations:

If the network between x, y, and z is disconnected:

* **CA**: Ensure data consistency (**C**). When x writes data, y can read it (**C**). Allow the system to continue providing services—even if only x and y are operational—ensuring it is readable and writable (**A**). We can only tolerate z not providing service; it cannot read or write, nor return incorrect data (losing **P**).

* **CP**: Ensure data consistency (**C**). Allow all three machines to provide services (even if only for reads) (**P**). We can only tolerate that x, y, and z cannot write (losing **A**).

* **AP**: Allow all three machines to write (**A**). Allow all three machines to provide services (reads count) (**P**). We can only tolerate that the data written by x and y doesn't reach z; z will return data inconsistent with x and y (losing **C**).

**CA** is exemplified by Paxos/Raft, which are majority protocols that sacrifice **P**; minority nodes remain completely silent. **CP** represents a read-only system; if a system is read-only, whether there's a network partition doesn't really matter—the tolerance to network partitions is infinitely large. **AP** is suitable for systems that only append and do not update—only inserts, no deletes or updates. Finally, by merging the results together, it can still function.
