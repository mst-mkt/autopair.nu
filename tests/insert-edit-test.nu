use std/assert
use std/testing *
use pairs.nu [pairs]
source ../autopair.nu


# | + ( -> (|), | + [ -> [|], | + { -> {|}
# | + " -> "|", | + ' -> '|', | + ` -> `|`
@test
def "insert-edit inserts the closing char after an opening one" [] {
  for pair in $pairs {
    let line = $"($pair.open)($pair.close)"
    assert equal (autopair insert-edit "" 0 $pair.open) { line: $line, pos: 1 } $"pair ($pair.open)"
  }
}

# (|) + ) -> ()|, [|] + ] -> []|, {|} + } -> {}|
# "|" + " -> ""|, '|' + ' -> ''|, `|` + ` -> ``|
@test
def "insert-edit skips over a closing char already at the cursor" [] {
  for pair in $pairs {
    let line = $"($pair.open)($pair.close)"
    assert equal (autopair insert-edit $line 1 $pair.close) { line: $line, pos: 2 } $"pair ($pair.close)"
  }
}

# |( + ( -> (|)(
@test
def "insert-edit does not skip an opening char at the cursor" [] {
  assert equal (autopair insert-edit "(" 0 "(") { line: "()(", pos: 1 }
}

# ab| cd + ( -> ab(|) cd
@test
def "insert-edit keeps the text around an inserted pair" [] {
  assert equal (autopair insert-edit "ab cd" 2 "(") { line: "ab() cd", pos: 3 }
}

# ab| + ) -> ab)|
@test
def "insert-edit inserts a lone closing char with nothing to skip" [] {
  assert equal (autopair insert-edit "ab" 2 ")") { line: "ab)", pos: 3 }
}

# (|] + ) -> ()|]
@test
def "insert-edit does not skip a closing char of another pair" [] {
  assert equal (autopair insert-edit "(]" 1 ")") { line: "()]", pos: 2 }
}

# a| + a -> aa|
@test
def "insert-edit inserts an unpaired char on its own" [] {
  assert equal (autopair insert-edit "a" 1 "a") { line: "aa", pos: 2 }
}

# cursor < 0 -> no edit
@test
def "insert-edit does nothing at a negative cursor" [] {
  assert equal (autopair insert-edit "()" (-1) "(") { line: "()", pos: -1 }
}

# あ| + ( -> あ(|)
@test
def "insert-edit counts chars, not bytes" [] {
  assert equal (autopair insert-edit "あ" 1 "(") { line: "あ()", pos: 2 }
}
