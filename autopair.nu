module autopair {
  const pairs = {
    "(": ")"
    "[": "]"
    "{": "}"
    '"': '"'
    "'": "'"
    "`": "`"
  }

  const spaces = [" " "\t" "\n" "\r"]

  def count-char [
    text: string
    char: string
  ]: nothing -> int {
    $text | split chars --grapheme-clusters | where {|c| $c == $char } | length
  }

  def balanced [
    open: string
    head: string
    tail: string
  ]: nothing -> bool {
    let close = ($pairs | get $open)

    if $open == $close {
      let quotes = ((count-char $head $open) + (count-char $tail $open))

      ($quotes mod 2) == 0
    } else {
      let unclosed = ((count-char $head $open) - (count-char $head $close))
      let unopened = ((count-char $tail $close) - (count-char $tail $open))

      ([$unclosed 0] | math max) >= $unopened
    }
  }

  def can-pair [
    char: string
    head: string
    tail: string
  ]: nothing -> bool {
    let closes = ($pairs | values)
    let brackets = ($closes | where {|c| $c not-in ($pairs | columns) })
    let left = ($head | split chars --grapheme-clusters | last 1 | str join)
    let right = ($tail | split chars --grapheme-clusters | first 1 | str join)
    let same_char = ($char == ($pairs | get $char))
    let right_free = ($right == "" or $right in $spaces or $right in $closes)
    let left_free = (not $same_char or ($left != $char and $left !~ '\w' and $left not-in $brackets))

    $right_free and $left_free and (balanced $char $head $tail)
  }

  export def insert-edit [
    line: string
    pos: int
    char: string
  ]: nothing -> record<line: string, pos: int> {
    if $pos < 0 { return { line: $line, pos: $pos } }

    let chars = ($line | split chars --grapheme-clusters)
    let head = ($chars | slice ..<$pos | str join)
    let tail = ($chars | slice $pos.. | str join)
    let inserted = (match $char {
      $c if $c in ($pairs | values) and ($tail | str starts-with $c) => ""
      $c if $c in ($pairs | columns) and (can-pair $c $head $tail) => $"($c)($pairs | get $c)"
      $c => $c
    })

    {
      line: $"($head)($inserted)($tail)"
      pos: ($pos + 1)
    }
  }

  export def insert [char: string] {
    let edited = (insert-edit (commandline) (commandline get-cursor) $char)
    commandline edit --replace $edited.line
    commandline set-cursor $edited.pos
  }

  export def backspace-edit [
    line: string
    pos: int
  ]: nothing -> record<line: string, pos: int> {
    if $pos <= 0 { return { line: $line, pos: $pos } }

    let chars = ($line | split chars --grapheme-clusters)
    let around = ($chars | slice ($pos - 1)..$pos | str join)
    let in_empty_pair = ($around in ($pairs | items {|open, close| $open + $close }))
    let deleted = if $in_empty_pair { [($pos - 1) $pos] } else { [($pos - 1)] }

    {
      line: ($chars | drop nth ...$deleted | str join)
      pos: ($pos - 1)
    }
  }

  export def backspace [] {
    let pos = (commandline get-cursor)
    if $pos <= 0 { return }

    let edited = (backspace-edit (commandline) $pos)
    commandline edit --replace $edited.line
    commandline set-cursor $edited.pos
  }

  def pair-chars []: nothing -> list<string> {
    $pairs
    | items {|open, close| [$open $close] }
    | flatten
    | uniq
  }

  export def keybindings []: nothing -> list<record> {
    pair-chars
    | each {|char|
      {
        name: $"autopair_insert_($char)"
        modifier: none
        keycode: $"char_($char)"
        mode: [emacs vi_insert]
        event: { send: executehostcommand, cmd: $"autopair insert ($char | to nuon)" }
      }
    }
    | append {
      name: autopair_backspace
      modifier: none
      keycode: backspace
      mode: [emacs vi_insert]
      event: { send: executehostcommand, cmd: "autopair backspace" }
    }
  }

  export def --env install [] {
    let own = (keybindings)

    $env.config.keybindings = (
      $env.config.keybindings
      | where name not-in ($own | get name)
      | append $own
    )
  }
}

use autopair
autopair install
