module autopair {
  const pairs = {
    "(": ")"
    "[": "]"
    "{": "}"
    '"': '"'
    "'": "'"
    "`": "`"
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

  export def keybindings []: nothing -> list<record> {
    $pairs
    | items {|open, close|
      {
        name: $"autopair_insert_($open)"
        modifier: none
        keycode: $"char_($open)"
        mode: [emacs vi_insert]
        event: [
          { edit: insertstring, value: $"($open)($close)" }
          { edit: moveleft }
        ]
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
