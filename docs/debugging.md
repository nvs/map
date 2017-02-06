# Debugging

The `debug` keyword can be used within JASS scripts to prefix certain
statements. This is standard JASS notation. Warcraft 3 simply ignores these
lines (although, it is not known if performance is affected). It can safely be
used in conjunction with the following JASS statements:

- `set`
- `if ...`
- `call`
- `loop ...`

For example:

```
function Debug_Example takes nothing returns nothing
    local index = 0

    // This line is ignored.
    debug set index = 1

    // This entire if-statement is ignored.
    debug if index == 1 then
    elseif index == 0 then
    else
        return
    endif

    // This call is ignored.
    debug call BJDisplayMsg ("Hello world!")

    // This infinite loop is ignored.
    debug loop
    endloop

    call BJDisplayMsg (I2S (index)) // 0
endfunction
```

The 'build' command extends upon this behavior without altering the standard
JASS language syntax, making the `debug` keyword more useful. When the
`options.debug` flag is set to `false`, debugging is essentially disabled.
Functionally, this does not really change anything, given that `debug` is
ignored by default. However, in an attempt to avoid potential side effects
(such as code bloat after optimization), statements prefixed with `debug` are
removed. With debugging disabled through the `flags.debug` setting, the above
becomes:

```
function Debug_Example takes nothing returns nothing
    local index = 0

    // This line is ignored.

    // This entire if-statement is ignored.

    // This call is ignored.

    // This infinite loop is ignored.

    call BJDisplayMsg (I2S (index)) // 0
endfunction
```

Now, if debugging is enabled by setting `flags.debug` to `true`, then all
lines modified by the `debug` keyword are kept. The keyword itself is the only
thing removed, and the rest of the code is left intact:

```
function Debug_Example takes nothing returns nothing
    local index = 0

    // This line is executed.
    set index = 1

    // This if-statement is not ignored.
    if index == 1 then
    elseif index == 0 then
    else
        return
    endif

    // This function is called.
    call BJDisplayMsg ("Hello world!") // Hello world!

    // This infinite loop is run, for better or worse.
    loop
    endloop

    // Never reached.
    call BJDisplayMsg (I2S (index))
endfunction
```

As such, care should be taken when using the `debug` keyword. However, it does
enable useful debugging functionality.

_There is a known issue with the included version of pjass. It does not
complain about `debug` being used in conjunction with `exitwhen` or `return`.
However, a map with such code will bug and not allow the player to enter the
game lobby._
