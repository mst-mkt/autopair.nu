dev:
  nu -n -e 'source autopair.nu'

test *args:
  nu -n -c 'use nutest; nutest run-tests --path tests --fail {{ args }}'
