use std/assert
use std/testing *
use pairs.nu [pair-chars]
source ../autopair.nu

# ( ) [ ] { } " ' ` + backspace = 10 bindings
@test
def "keybindings returns one binding per pair char plus backspace" [] {
  assert equal (autopair keybindings | length) ((pair-chars | length) + 1)
}

@test
def "keybindings gives every binding a unique name" [] {
  let names = (autopair keybindings | get name)
  assert equal ($names | uniq | length) ($names | length)
}

# ( ) [ ] { } " ' ` -> autopair insert
@test
def "keybindings binds each pair char to the autopair command" [] {
  for char in (pair-chars) {
    let expected = {
      name: $"autopair_insert_($char)"
      modifier: none
      keycode: $"char_($char)"
      mode: [emacs vi_insert]
      event: { send: executehostcommand, cmd: $"autopair insert ($char | to nuon)" }
    }
    assert equal (autopair keybindings | where name == $expected.name | first) $expected $"char ($char)"
  }
}

# " -> autopair insert "\""
@test
def "keybindings quotes the char it passes to the autopair command" [] {
  let binding = (autopair keybindings | where name == 'autopair_insert_"' | first)
  assert equal $binding.event.cmd 'autopair insert "\""'
}

# backspace -> autopair backspace
@test
def "keybindings binds backspace to the autopair command" [] {
  assert equal (autopair keybindings | where name == "autopair_backspace" | first) {
    name: autopair_backspace
    modifier: none
    keycode: backspace
    mode: [emacs vi_insert]
    event: { send: executehostcommand, cmd: "autopair backspace" }
  }
}

@test
def "install adds every binding to the config" [] {
  $env.config.keybindings = []
  autopair install
  assert equal ($env.config.keybindings | length) ((pair-chars | length) + 1)
  assert equal $env.config.keybindings (autopair keybindings)
}

@test
def "install does not duplicate bindings when run twice" [] {
  $env.config.keybindings = []
  autopair install
  autopair install
  assert equal ($env.config.keybindings | length) ((pair-chars | length) + 1)
}

# an autopair binding left over from an older version -> replaced
@test
def "install replaces a stale binding of its own" [] {
  $env.config.keybindings = [
    { name: autopair_backspace, modifier: none, keycode: backspace, mode: emacs, event: { send: enter } }
  ]
  autopair install

  assert equal ($env.config.keybindings | where name == "autopair_backspace" | first) {
    name: autopair_backspace
    modifier: none
    keycode: backspace
    mode: [emacs vi_insert]
    event: { send: executehostcommand, cmd: "autopair backspace" }
  }
  assert equal ($env.config.keybindings | length) ((pair-chars | length) + 1)
}

@test
def "install keeps bindings it does not own" [] {
  let other = { name: "other", modifier: none, keycode: char_z, mode: emacs, event: null }
  $env.config.keybindings = [$other]
  autopair install
  assert equal ($env.config.keybindings | first) $other
  assert equal ($env.config.keybindings | length) ((pair-chars | length) + 2)
}
