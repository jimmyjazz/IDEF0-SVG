## What's IDEF0-SVG
Produces [IDEF0](https://en.wikipedia.org/wiki/IDEF0) (aka ICOM) process diagrams from a simple DSL.

The code itself is a few shell scripts in [`bin`](bin) wrapped around some Ruby code in [`lib`](lib) providing DSL parsing, SVG generation, and an ad-hoc informally-specified bug-ridden slow implementation of half a constraint solver.

## The DSL
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
* `is composed of` - a sub-Function

For example, a DSL representation of IDEF0 might look like:

```
Function receives Input
Function respects Control
Function produces Output
Function requires Mechanism
Function is composed of Function
```

And can be rendered to:

![IDEF0](samples/idef0-concepts.svg)

There are some more samples in ... wait for it ... [`samples`](samples).

## Usage

To generate a complete schematic of a system described in the DSL:

```
$ bin/schematic <samples/cook-pizza.idef0
<?xml version="1.0" encoding="UTF-8" standalone="no"?>
...
</svg>
```

This will output the SVG to the screen. Redirect it to a file with:

```
$ bin/schematic <samples/cook-pizza.idef0 >output.svg
```

You can then open the `output.svg` file in your web browser or other SVG viewer/editor:

![Cook Pizza](samples/cook-pizza.svg)

Because IDEF0 diagrams can be nested, the DSL supports decomposition of functions into sub-functions via the `is composed of` predicate. The full schematic of such a model might be too large to comprehend on a single page, so the following commands can be used to make larger models easier to understand.

To render only the top level functions of a system:

```
$ bin/decompose <"samples/operate bens burgers.idef0" >output.svg
```

![Operate Ben's Burgers - decompose](samples/operate%20bens%20burgers%20-%20decompose.svg)

Compare the output from the above command with the much harder to comprehend:

```
$ bin/schematic <"samples/operate bens burgers.idef0" >output.svg
```

![Operate Ben's Burgers - schematic](samples/operate%20bens%20burgers%20-%20schematic.svg)

To see a "table of contents" view of an IDEF0 model, use the `toc` command:

```
$ bin/toc <"samples/operate bens burgers.idef0"
Operate Ben's Burgers
  Oversee Business Operations
  Expand The Business
  Manage Local Restaurant
    Manage Restaurant Staff
    Order Supplies
      Evaluate Suppliers
      Select Supplier For Order
      Generate Order Form
      Submit Order
      Track Orders
    Increase Local Business
    Keep Accounts
    Report To Management
  Provide Supplies
  Serve Customers
```

You can then take the name of one of the sub-functions and generate a diagram for it:

```
$ bin/decompose "Order Supplies" <"samples/operate bens burgers.idef0" >output.svg
```

Finally, to focus on a single function and just show all of its inputs, outputs, controls and mechanisms, use the `focus` command:

```
$ bin/focus "Order Supplies" <"samples/operate bens burgers.idef0" >output.svg
```

![Operate Ben's Burgers - focus](samples/operate%20bens%20burgers%20-%20focus.svg)

## Some things to do

* All the `# TODO`s in the code
* Some tests wouldn't go astray
* Revisit the [building blocks](https://en.wikipedia.org/wiki/IDEF0#IDEF0_Building_blocks) and see what else we need to implement
* Sharing external concepts (they appear twice currently)
* Resizing of boxes based on text length (abstraction text vs label)

## License

This software is released under the [MIT License](https://opensource.org/licenses/MIT).
