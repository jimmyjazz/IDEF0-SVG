## What's IDEF0-SVG
Produces [IDEF0](https://en.wikipedia.org/wiki/IDEF0) (aka ICOM) process diagrams from a simple DSL.

The DSL is a list of statements of the form: `Function predicate Concept`.

`Function` names are space-separated and camel-cased, and identify an activity, process, or transformation to perform.

`Concept` names are space-separated and camel-cased, and identify an instance of one of the following:

* Function - an ctivity, process, or transformation
* Input - the data or objects acted on by a Function
* Control - (aka Guidance) the policies that govern the behaviour of a Function
* Output - the result of performing a Function
* Mechanism - (aka Enabler) the means by which a Function is performed

`predicate` defines the nature of `Concept` relative to `Function`, and must be one of:

* `receives` - an Input
* `respects` - a Control
* `produces` - an Output
* `requires` - a Mechanism
* `is composed of` - indicating a nested Function

For example, a DSL representation of IDEF0 might look like:

```
Function receives Input
Function respects Control
Function produces Output
Function requires Mechanism
Function is composed of Function
```

There are some more samples in ... wait for it ... `samples`.

The code itself is a few shell scripts in `bin` wrapped around some Ruby code in `lib` providing DSL parsing, SVG generation, and an ad-hoc informally-specified bug-ridden slow implementation of half a constraint solver.

## Some things to do

* All the `# TODO`s in the code
* Some tests wouldn't go astray
* Composition (`is composed of`) is b0rked
* Revisit the [building blocks](https://en.wikipedia.org/wiki/IDEF0#IDEF0_Building_blocks) and see what else we need to implement
* Sharing external concepts (they appear twice currently)
* Resizing of boxes based on text length (abstraction text vs label)

## License

This software is released under the [MIT License](https://opensource.org/licenses/MIT).
