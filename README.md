# ssh_funcify

A `Bash` _library_ for _sending_ **declared** functions with args to a remote host via `ssh` and executing them there.

## The Point

A main goal is to get the convenience of being able to **declare** and edit _remote_ functions in an IDE, rather than
having to _declare_ the functions in convoluted strings, where the editor can't help you with syntax highlighting, etc.
It also makes it easy to send even complex nested functions to the remote host.

There is also some robustness against syntax errors caused by _plings_ and such in the function body.

There is also some convenient error handling and debug-logging.

## Notes

### fail-function

`ssh_funcify` assumes access to a declared function `fail` which is declared for the test in `__utilifize` in
`ssh_funcify_test.sh`.

### ssh config

You will have to ponder `ssh_host='_localisolatee`'.

## Usage

Is illustrated in `ssh_funcify_test.sh`.

## Grokage
Understanding [Bash Dynamic Scope](https://benmyers.dev/blog/scope/) is prolly a good idea to follow variables.

## Boldness of attack

Should you feel like blurting anything at all ... knock `yourself` out.
