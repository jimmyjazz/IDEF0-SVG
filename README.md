## What's IDEF0-SVG
Produce [IDEF0](https://en.wikipedia.org/wiki/IDEF0) process diagrams from a simple DSL.

The DSL is a list of statements of the form `Subject predicate Object`.

Both `Subject` and `Object` are space-separated camel-cased nouns that denote Concepts:

* Function - an activity, process, or transformation
* Input - the data or objects acted on by a Function
* Control - the policies that govern the behaviour of a Function
* Output - the result of performing a Function
* Mechanism - the means by which an Function is performed

A `predicate` defines the nature of the relationship between a Function (as `Subject`) and another Concept (as `Object`), and must be one of:

* `receives` - indicating an Input
* `respects` - indicating a Control
* `produces` - indicating an Output
* `requires` - indicating a Mechanism
* `is composed of` - indicating a nested Function

For example, a DSL representation of IDEF0 (aka ICOM) might look like:

```
Function receives Input
Function respects Control
Function produces Output
Function requires Mechanism
Function is composed of Nested Function
```

There are some more samples in ... wait for it ... `samples`.

The code itself is a few shell scripts in `bin` wrapped around some Ruby code in `lib` providing DSL parsing, SVG generation, and an ad-hoc informally-specified bug-ridden slow implementation of half a constraint solver.

## Some things to do

* All the `#TODO`s in the code
* Some tests wouldn't go astray
* Revisit the [building blocks](https://en.wikipedia.org/wiki/IDEF0#IDEF0_Building_blocks) and see what else we need to implement
* Sharing external concepts (they appear twice currently)
* Resizing of boxes based on text length (abstraction text vs label)

## License

This software is released under the [MIT License](https://opensource.org/licenses/MIT).
