#!/bin/bash

__functionize_test() {
  print_func 'BEGIN'
  source "$(dirname "${BASH_SOURCE[0]}")/ssh_funcify.lib.sh" ||
    fail 1 'Could not load ssh_funcify.lib.sh'

  func1() {
    echo "ECHO FROM func1; $(whoami)@$(hostname); 'something plinged' ($*)"
  }

  func2() {
    # Showcasing function with subfunction as a more complex example.
    subfunc() {
      echo "ECHO FROM subfunc(2); $(whoami)@$(hostname); 'pling' ($*)"
    }

    subfunc "$@"
  }

  func_failing() {
    echo "ECHO FROM func_failing; $(whoami)@$(hostname); 'something plinged' ($*)"
    return 65
  }

  flow() {
    declare ssh_host func_name func_args

    reset_args() {
      ssh_host='_localisolatee'
      func_name='func1'
      func_args=('a1' 'a2')
    }

    responsify() {
      _printf '\033[34m responsify: \033[90m %s %s %s\033[0m\n' \
        "${ssh_host}" "${func_name}" "${func_args[*]}"
      declare response ansi
      if response=$(ssh_funcify "${ssh_host}" "${func_name}" "${func_args[@]}"); then
        ansi=32
      else
        [[ -n ${response} ]] || response='no response'
        ansi=33
      fi
      _printf '\033[35m response:\n\033[%sm %s\033[0m\n' \
        "${ansi}" "${response}"
    }

    testify() {
      _printf '\033[94m\n testify %s:\033[0m\n' "$*"
      responsify
    }

    reset_args
    testify 'good 1'
    ##
    reset_args
    func_name='func2'
    testify 'func2'
    ##
    reset_args
    ssh_host=''
    testify 'no-host'
    ##
    reset_args
    func_name=''
    testify 'no-func_name'
    ##
    reset_args
    declare func_name='bad_func'
    testify 'bad_func'
    ##
    reset_args
    ssh_host='bad-host'
    testify 'bad_host'
    ##
    reset_args
    declare func_name='func_failing'
    testify 'func_failing'
    ##

    echo
  }

  flow

  print_func 'DONE'
}

__utilifize() {
  _print() {
    # Prints pre-formatted text to stderr.
    printf '%b' "$*" >&2
  }

  _printf() {
    # Formats text and prints it to stderr.
    # shellcheck disable=SC2059
    printf "$@" >&2
  }

  pransi() {
    declare ansi="$1"
    shift
    while IFS= read -r l; do
      _print "\033[${ansi}m${l}\033[0m\n"
    done <<<"$@"
  }

  fail() {
    declare -i exit_code="$1"
    shift
    pransi '91' "(${exit_code}) $*"
    exit "${exit_code}"
  }

  remark() {
    pransi '35' "$@"
  }

  print_func() {
    function_name="${FUNCNAME[1]}"
    pransi '36' "${function_name}" "$@"
  }

}

__utilifize
__functionize_test
