use std/assert
use std/testing *
use fixtures.nu [pairs grapheme_clusters]
source ../autopair.nu


# |() -> |()
@test
def "backspace-edit keeps the line when the cursor is at the start" [] {
  assert equal (autopair backspace-edit "()" 0) { line: "()", pos: 0 }
}

# cursor < 0 -> no edit
@test
def "backspace-edit does nothing at a negative cursor" [] {
  assert equal (autopair backspace-edit "()" (-1)) { line: "()", pos: -1 }
}

# (|) -> |, [|] -> |, {|} -> |
# "|" -> |, '|' -> |, `|` -> |
@test
def "backspace-edit deletes both chars inside an empty pair" [] {
  for pair in $pairs {
    let line = $"($pair.open)($pair.close)"
    assert equal (autopair backspace-edit $line 1) { line: "", pos: 0 } $"pair ($line)"
  }
}

# ab(|)cd -> ab|cd
@test
def "backspace-edit keeps the text around a deleted pair" [] {
  assert equal (autopair backspace-edit "ab()cd" 3) { line: "abcd", pos: 2 }
}

# ab| -> a|
@test
def "backspace-edit deletes one char in plain text" [] {
  assert equal (autopair backspace-edit "ab" 2) { line: "a", pos: 1 }
}

# (|a) -> |a)
@test
def "backspace-edit deletes one char when the pair is not empty" [] {
  assert equal (autopair backspace-edit "(a)" 1) { line: "a)", pos: 0 }
}

# (|] -> |]
@test
def "backspace-edit deletes one char when the delimiters do not match" [] {
  assert equal (autopair backspace-edit "(]" 1) { line: "]", pos: 0 }
}

# ()| -> (|
@test
def "backspace-edit deletes one char when the cursor is past the pair" [] {
  assert equal (autopair backspace-edit "()" 2) { line: "(", pos: 1 }
}

# あい| -> あ|
@test
def "backspace-edit counts chars, not bytes" [] {
  assert equal (autopair backspace-edit "あい" 2) { line: "あ", pos: 1 }
}

# 👨‍👩‍👧| -> |, 🇯🇵| -> |, 🫶🏻| -> |
@test
def "backspace-edit deletes a whole grapheme cluster" [] {
  for cluster in $grapheme_clusters {
    assert equal (autopair backspace-edit $cluster 1) { line: "", pos: 0 } $"cluster ($cluster)"
  }
}

# a🫶🏻|b -> a|b
@test
def "backspace-edit indexes the line by graphemes" [] {
  assert equal (autopair backspace-edit "a🫶🏻b" 2) { line: "ab", pos: 1 }
}
