module autopair {
  const pairs = {
    "(": ")"
    "[": "]"
    "{": "}"
    '"': '"'
    "'": "'"
    "`": "`"
  }

  export def insert-edit [
    line: string
    pos: int
    char: string
  ]: nothing -> record<line: string, pos: int> {
    if $pos < 0 { return { line: $line, pos: $pos } }

    let chars = ($line | split chars)
    let head = ($chars | slice ..<$pos | str join)
    let tail = ($chars | slice $pos.. | str join)
    let right = ($chars | get --optional $pos | default "")
    let inserted = (match $char {
      $c if $c == $right and $c in ($pairs | values) => ""
      $c if $c in ($pairs | columns) => $"($c)($pairs | get $c)"
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

    let chars = ($line | split chars)
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
