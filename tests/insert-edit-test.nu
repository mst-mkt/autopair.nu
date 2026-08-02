use std/assert
use std/testing *
use fixtures.nu [pairs grapheme_clusters]
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

# |( + ( -> (|(
@test
def "insert-edit does not skip an opening char at the cursor" [] {
  assert equal (autopair insert-edit "(" 0 "(") { line: "((", pos: 1 }
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

# | "" + " -> "|" ""
@test
def "insert-edit does not skip a closing char away from the cursor" [] {
  assert equal (autopair insert-edit ' ""' 0 '"') { line: '"" ""', pos: 1 }
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

# 👨‍👩‍👧| + ( -> 👨‍👩‍👧(|), 🇯🇵| + ( -> 🇯🇵(|), 🫶🏻| + ( -> 🫶🏻(|)
@test
def "insert-edit does not split a grapheme cluster" [] {
  for cluster in $grapheme_clusters {
    let line = ($cluster + "()")
    assert equal (autopair insert-edit $cluster 1 "(") { line: $line, pos: 2 } $"cluster ($cluster)"
  }
}

# a🫶🏻|b + ( -> a🫶🏻(|b
@test
def "insert-edit indexes the line by graphemes" [] {
  assert equal (autopair insert-edit "a🫶🏻b" 2 "(") { line: "a🫶🏻(b", pos: 3 }
}

# | x + " -> "|" x
@test
def "insert-edit pairs at the start of a non-empty line" [] {
  assert equal (autopair insert-edit " x" 0 '"') { line: '"" x', pos: 1 }
}

# |foo + ( -> (|foo, |foo + " -> "|foo
@test
def "insert-edit does not pair in front of a word char" [] {
  for pair in $pairs {
    let line = $"($pair.open)foo"
    assert equal (autopair insert-edit "foo" 0 $pair.open) { line: $line, pos: 1 } $"pair ($pair.open)"
  }
}

# |-flag + ( -> (|-flag
@test
def "insert-edit does not pair in front of a symbol" [] {
  assert equal (autopair insert-edit "-flag" 0 "(") { line: "(-flag", pos: 1 }
}

# |　x + ( -> (|　x
@test
def "insert-edit does not pair in front of a non-ascii space" [] {
  assert equal (autopair insert-edit "　x" 0 "(") { line: "(　x", pos: 1 }
}

# |<tab>x + ( -> (|)<tab>x
@test
def "insert-edit pairs in front of a tab" [] {
  assert equal (autopair insert-edit "\tx" 0 "(") { line: "()\tx", pos: 1 }
}

# $"|" + ( -> $"(|)"
@test
def "insert-edit pairs in front of a closing quote" [] {
  assert equal (autopair insert-edit '$""' 2 "(") { line: '$"()"', pos: 3 }
}

# (|) + ( -> ((|)), [|] + ( -> [(|)], {|} + ( -> {(|)}
@test
def "insert-edit pairs in front of a closing bracket" [] {
  for pair in ($pairs | where {|p| $p.open != $p.close }) {
    let before = $"($pair.open)($pair.close)"
    let line = ($pair.open + "()" + $pair.close)
    assert equal (autopair insert-edit $before 1 "(") { line: $line, pos: 2 } $"pair ($pair.close)"
  }
}

# foo|) + ( -> foo(|), foo|] + [ -> foo[|], foo|} + { -> foo{|}
@test
def "insert-edit does not pair in front of an unmatched closing bracket" [] {
  for pair in ($pairs | where {|p| $p.open != $p.close }) {
    let before = $"foo($pair.close)"
    let line = $"foo($pair.open)($pair.close)"
    assert equal (autopair insert-edit $before 3 $pair.open) { line: $line, pos: 4 } $"pair ($pair.open)"
  }
}

# (foo|) + ( -> (foo(|)), [foo|] + [ -> [foo[|]], {foo|} + { -> {foo{|}}
@test
def "insert-edit pairs in front of a closing bracket that has an opening one" [] {
  for pair in ($pairs | where {|p| $p.open != $p.close }) {
    let before = $"($pair.open)foo($pair.close)"
    let line = $"($pair.open)foo($pair.open)($pair.close)($pair.close)"
    assert equal (autopair insert-edit $before 4 $pair.open) { line: $line, pos: 5 } $"pair ($pair.open)"
  }
}

# foo|] + ( -> foo(|)]
@test
def "insert-edit counts each bracket kind on its own" [] {
  assert equal (autopair insert-edit "foo]" 3 "(") { line: "foo()]", pos: 4 }
}

# ())| + ( -> ())(|)
@test
def "insert-edit pairs with unmatched closing brackets behind the cursor" [] {
  assert equal (autopair insert-edit "())" 3 "(") { line: "())()", pos: 4 }
}

# (a)|) + ( -> (a)(|)
@test
def "insert-edit does not count a closed bracket behind the cursor" [] {
  assert equal (autopair insert-edit "(a))" 3 "(") { line: "(a)()", pos: 4 }
}

# | (foo) + ( -> (|) (foo)
@test
def "insert-edit does not count a closed bracket ahead of the cursor" [] {
  assert equal (autopair insert-edit " (foo)" 0 "(") { line: "() (foo)", pos: 1 }
}

# don| + ' -> don'|, don| + " -> don"|
@test
def "insert-edit does not pair a quote after a word char" [] {
  for pair in ($pairs | where {|p| $p.open == $p.close }) {
    let line = $"don($pair.open)"
    assert equal (autopair insert-edit "don" 3 $pair.open) { line: $line, pos: 4 } $"quote ($pair.open)"
  }
}

# あ| + ' -> あ'|
@test
def "insert-edit treats a non-ascii char as a word char" [] {
  assert equal (autopair insert-edit "あ" 1 "'") { line: "あ'", pos: 2 }
}

# foo()| + " -> foo()"|
@test
def "insert-edit does not pair a quote after a closing bracket" [] {
  assert equal (autopair insert-edit "foo()" 5 '"') { line: 'foo()"', pos: 6 }
}

# ""| + " -> """|
@test
def "insert-edit does not pair a quote after the same quote" [] {
  for pair in ($pairs | where {|p| $p.open == $p.close }) {
    let before = $"($pair.open)($pair.open)"
    let line = $"($pair.open)($pair.open)($pair.open)"
    assert equal (autopair insert-edit $before 2 $pair.open) { line: $line, pos: 3 } $"quote ($pair.open)"
  }
}

# "| + ' -> "'|'
@test
def "insert-edit pairs a quote after a different quote" [] {
  assert equal (autopair insert-edit '"' 1 "'") { line: "\"''", pos: 2 }
}

# foo=| + ' -> foo='|'
@test
def "insert-edit pairs a quote after a symbol" [] {
  assert equal (autopair insert-edit "foo=" 4 "'") { line: "foo=''", pos: 5 }
}

# "foo.| + " -> "foo."|, 'foo.| + ' -> 'foo.'|, `foo.| + ` -> `foo.`|
@test
def "insert-edit closes a quote left open earlier in the line" [] {
  for pair in ($pairs | where {|p| $p.open == $p.close }) {
    let before = $"($pair.open)foo."
    let line = $"($pair.open)foo.($pair.open)"
    assert equal (autopair insert-edit $before 5 $pair.open) { line: $line, pos: 6 } $"quote ($pair.open)"
  }
}

# | " + " -> "| "
@test
def "insert-edit counts quotes on both sides of the cursor" [] {
  assert equal (autopair insert-edit ' "' 0 '"') { line: '" "', pos: 1 }
}

# "a" | + " -> "a" "|"
@test
def "insert-edit pairs a quote when the line has no open one" [] {
  assert equal (autopair insert-edit '"a" ' 4 '"') { line: '"a" ""', pos: 5 }
}

# feat| + ( -> feat(|)
@test
def "insert-edit pairs a bracket after a word char" [] {
  assert equal (autopair insert-edit "feat" 4 "(") { line: "feat()", pos: 5 }
}

# foo()| + [ -> foo()[|]
@test
def "insert-edit pairs a bracket after a closing bracket" [] {
  assert equal (autopair insert-edit "foo()" 5 "[") { line: "foo()[]", pos: 6 }
}
