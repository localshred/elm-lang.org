import Website.Skeleton (skeleton)
import Website.Tiles as Tile
import Window

port title : String
port title = "Elm 0.13"

main = skeleton "Blog" everything <~ Window.dimensions

everything wid =
    let w = min 600 wid
    in  flow down
        [ width w content
        ]

content = [markdown|

<br>

# Elm 0.13

A big part of this release is an architecture improvement for the compiler.
In addition to making the compiler code nicer to work with, it made it really
easy to fix a couple long-standing issues surrounding imports and exports. The
major improvements you will see as a user include:

    * Better error messages on ambiguous variables.
    * Nicer import and export mechanisms for ADTs.
    * Cleaner and more consistent standard libraries.
    * Type aliases can be used with ports.

In pursuit of these improvements, we made some breaking changes, so these
release notes are a nice overview of what has changed and how to upgrade your
code to use 0.13. To install or upgrade, follow [these directions][install].

[install]: https://github.com/elm-lang/elm-platform/blob/master/README.md

## Imports and Exports

The code that manages importing and exporting ADTs has been improved a lot. As
part of those fixes, there is now a new syntax for importing and exporting
ADTs. Let's look at a couple cases:

```haskell
import Maybe ( Maybe(..) )    -- the type and all constructors

import Maybe ( Maybe(Just) )  -- the type and some constructors

import Maybe ( Maybe )        -- the type but no constructors
```

All of the same patterns can be used when exporting ADTs from modules, so you
can expose only what you want to. This change may break some code, so keep this
new syntax in mind when you are updating your code for 0.13.

Another result of this architecture improvement is that the error messages for
ambiguous variables work properly now. For example, the following code will
tell you that your use of `map` is ambiguous: 

```haskell
import List (map)
import Set (map)

myMap = map         -- ambiguous!
```

It does not know if you mean `List.map` or `Set.map`. If you have defined your
own version of `map` within the module, that version will take precedence.
So the following code is unambiguous:

```haskell
import List (..)
import Set (..)

map = "http://maps.google.com"

myMap = map
```

The local definition will always take precedence. When upgrading, you may run
into some code that needs to be disambiguated. Keep in mind that it is usually
best to use qualified names in the first place. Writing `Set.map` means that
your code can never *become* ambiguous if someone adds a `map` function to a
library you imported unqualified. Furthermore, it is very helpful for people
reading your code for the first time.


## Cleaning up the Standard Libraries

Quite a few functions have been added, renamed, and removed in an effort to
make the standard libraries more predictable and to help produce nicer code.
Here are all the changes:

  * **`Basics`**
    * `(.)` is replaced by `(<<)` and `(>>)`
    * `id` is replaced by `identity`
    * `div` is replaced by `(//)`
    * `mod` is replaced by `(%)`
    * `sqrt` and `logBase` only work on Floats
    * `(negate : number -> number)` has been added

  * **`List`**
    * Added `(indexedMap : (Int -> a -> b) -> [a] -> [b])`
    * Added `(filterMap : (a -> Maybe b) -> [a] -> [b])`
    * Removed `and` and `or`

  * **`Maybe`**
    * Added `(map : (a -> b) -> Maybe a -> Maybe b)`
    * `justs` is replaced by `(List.filterMap identity)`

The changes in `Basics` are probably the most far reaching, so I think they
deserve a proper defense. See [this thread][renaming] to see the arguments
for renaming `id`, `div`, and `mod`. The toughest decision was about function
composition, so the next section is devoted to explaining that choice.

[renaming]: https://groups.google.com/forum/#!searchin/elm-discuss/div$20mod$20id/elm-discuss/uuKEqENZZm8/bKs5k-suzJsJ


### The new Function Composition Operators

Function composition is now done with the following operators:

```haskell
(>>) : (a -> b) -> (b -> c) -> (a -> c)

(<<) : (b -> c) -> (a -> b) -> (a -> c)
```
This matches the syntax from F#. This is an improvement because (1) Elm has
special record accessor functions that look very bad with the old composition
operator and (2) adding the `(>>)` operator means you can write function
compositions that read left to right.

Here is an illustration of mixing function composition with record accessors:

```haskell
-- Old way
filter (not . .checked) entries

-- New way
filter (not << .checked) entries
```

You no longer get two dots in a row. Now let's write the `step` function from
[the Mario example][mario] a couple different ways to see how this will change
code in more typical situations:

[mario]: /edit/examples/Intermediate/Mario.elm

```haskell
-- Haskell-inspired way
step (dt, keys) =
    physics dt . walk keys . gravity dt . jump keys

-- F# way with function composition
step (dt, keys) =
    jump keys >> gravity dt >> walk keys >> physics dt

-- F# way with forward application
step (dt, keys) mario =
    mario
        |> jump keys
        |> gravity dt
        |> walk keys
        |> physics dt
```

I think the two F# inspired styles are clearer, especially for programmers
coming from a background in which dots are used exclusively for accessing
objects. Both F# inspired operators also indicate the direction of flow very
clearly, so even if you are not familiar with them, you can have some idea of
what they are doing.

I personally prefer forward application because it looks great when you put
each step on its own line. This style makes your code more regular and
therefore easy to glance through. If someone adds a step, the diff will clearly
show that only that line was added. If someone changes an argument, the diff
will clearly show that that particular step was modified. I also like this
style because it requires that you explicitly name all of your arguments. This
kind of hint is extremely valuable when reading unfamiliar code.

It is pretty easy to replace `(.)` with `(<<)`. The operator is typically
surrounded by spaces, so you can find and replace it pretty safely. Longer
term, it may be worthwhile to consider switching to `(>>)` or `(|>)`.


## Miscellaneous Improvements

Elm uses [ports][] to communicate with JavaScript. You can now use type aliases
when defining ports. This means it is much nicer to send large records through
ports.

There is now a `--bundle-runtime` flag which creates stand-alone Elm programs.
It adds the runtime system to the generated code, so you do not need to link
it.

Previous iterations of Elm depended on the Pandoc project. Pandoc is great and
extremely useful, but it includes lots of functionality that Elm does not need
and brings in a large number of dependencies that led to build problems quite
frequently. Elm 0.13 uses a library called cheapskate for markdown parsing.

[ports]: /learn/Ports.elm


## Thank you

Huge thank you to [Michael B. James][michael] and [Andrew Shulayev][andrew] who
joined the Elm team as interns this summer! The major parts of their projects
will be coming out in the following days and weeks, but some improvements can
already be announced. Thanks to Michael for figuring out how to build the
entire Elm platform with cabal sandboxes, this makes installing much nicer
on non-Windows and non-Mac platforms! Thanks to Andrew for making the
documentation parser less ad-hoc. Thank you to both of you for talking through
issues and design choices. I learned a lot working with you and had a ton of
fun! On that note, thank you too [Laszlo Pandy][laszlo] for helping me
improve as a leader and manager and person; this summer felt like a big deal
for me.

[michael]: https://github.com/michaelbjames
[andrew]: https://github.com/ddrone
[laszlo]: https://github.com/laszlopandy

Massive thank you to [Attila Gazso][agazso] for improving the installers. I
used to be really wary of working on them, but you laid a great foundation
for [Elm Platform][platform] that helped me learn a ton about the tools and
processes needed. I continue to be surprised by the kinds of crazy and
creative fixes we end up using. I never imagined VBScript would make it into
an Elm repo!

[agazso]: https://github.com/agazso
[platform]: https://github.com/elm-lang/elm-platform

Thank you to [Christian Widera](https://github.com/Xashili) for continuing to
improve [the Array library][array]. Thanks to [Daniel Heres][dan] for fixing
a layout bug. Thank you [Max New][max] for continuing to improve testing and
build process. I think We are at a point now where the benefits of these
efforts has become extremely obvious, it is great!

[dan]: https://github.com/Dandandan
[array]: http://library.elm-lang.org/catalog/elm-lang-Elm/latest/Array
[max]: https://github.com/maxsnew

Finally, thank you to [Peter Halacsy][hp] and [Prezi][] for your support! You
have helped this project and community enormously. The progress is so obvious
looking back over the past year and a half, and there is no way it would have
happened so quickly or so smoothly without your help. Thank you!

[hp]: https://twitter.com/halacsy
[Prezi]: https://prezi.com/
|]