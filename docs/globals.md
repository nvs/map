# Globals

All globals meeting specific criteria will be available within Lua scripts
used during the 'constants' and 'objects' commands. They will be exposed
through a global `table` named 'globals'. This includes those present within
both the 'common.j' and 'blizzard.j', as well as any within user provided
scripts.

The criteria for globals to be considered are as follows:

1. The global must be declared as constant.
2. The global must be one of the following types:
    - Boolean
    - String
    - Real
    - Integer
3. The global must be assigned a constant value.

Examples of valid globals:

```
constant boolean BOOLEAN_A = true
constant boolean BOOLEAN_B = false

constant string STRING_A = ""
constant string STRING_B = "Hello, world!"

constant real REAL_A = 3.1415926
constant real REAL_B = .50
constant real REAL_C = 0.

constant integer INTEGER_A = 1234
constant integer INTEGER_B = 07
constant integer INTEGER_C = 0xAFF
constant integer INTEGER_D = $ABC1
constant integer INTEGER_E = 'A'
constant integer INTEGER_F = 'A000'
```

Examples of invalid globals:

```
boolean BOOLEAN_C = true
constant boolean BOOLEAN_D = BOOLEAN_C
constant boolean BOOLEAN_E = true and false

constant string STRING_C = "Multiple" + " " + "Parts"
constant string STRING_D = STRING_B + " And you too!"

constant real_C = REAL_A * 5.00
constant real_D = globals.bj_PI

integer INTEGER_G = 1
constant integer_H = 5 + 5 + INTEGER_A
```

In order to faciliate easier understanding of the contents of said globals,
both its JASS type and value are exposed within the `table` that represents
the global. Do realize that all values wil be of the Lua type `string`, and it
is left up to the user to decide if they wish to transform these values
further. For example:

```
globals.FALSE.jass_type               --> 'boolean'
globals.FALSE.value                   --> 'false'

globals.JASS_MAX_ARRAY_SIZE.jass_type --> 'integer.decimal'
globals.JASS_MAX_ARRAY_SIZE.value     --> '8192'

globals.bj_PI.jass_type               --> 'real'
globals.bj_PI.value                   --> '3.14159'

globals.INTEGER_F.jass_type           --> 'integer.code'
globals.INTEGER_F.value               --> 'A000'
```

As for the JASS types exposed to Lua, the following names are used:

- `'boolean'`
- `'string'`
- `'real'`
- `'integer.literal'`
- `'integer.code'`
- `'integer.hexadecimal'`
- `'integer.octal'`
- `'integer.decimal'`
