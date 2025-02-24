#!/bin/bash

# ssh_funcify - Remote Function Execution Transport
#
# Purpose:
#   Transports and executes shell functions on remote hosts via SSH while maintaining:
#   - Function definition integrity (proper escaping)
#   - Argument passing
#   - Error propagation and detailed reporting
#
# Parameters:
#   $1 - address   : Remote host address (required)
#   $2 - func_name : Name of function to transport and execute (required)
#   $* - args      : Arguments to pass to the remote function (optional)
#
# Exit Codes:
#   64  - Input validation failures (missing address/function, undefined function)
#   255 - SSH connection failures (timeout, host unreachable, auth failures)
#   127 - Remote shell unavailable
#   *   - Original exit code from the remote function execution
#
# Security Notes:
#   - Uses non-interactive SSH with strict timeouts
#   - Disables host key checking for automation purposes - ensure trusted network
#   - Consider implications in production environments
#
# Requirements:
#   - SSH access to remote host
#   - bash shell available on remote host
#   - Proper quoting of function arguments containing spaces/special chars
ssh_funcify() {
  # Transport and execute shell functions remotely via SSH
  # Maintains function definition integrity and proper error propagation
  declare address="$1"
  shift
  declare func_name="$1"
  shift
  declare -a args=("$@")
  declare func_txt escaped_func_txt escaped_args cmd remote_cmd ssh_response error_file
  declare error_msg='undefined error message'

  prepare() {
    func_txt=$(declare -f 'fail') || {
      echo "Could not load 'fail' function"
      exit 1
    }
    # Validate inputs and construct properly escaped remote execution command
    [[ -n "${address}" ]] || {
      fail 64 "ssh_funcify: missing address"
    }
    [[ -n "${func_name}" ]] || {
      fail 64 "ssh_funcify: missing function name"
    }
    func_txt=$(declare -f "${func_name}") || {
      fail 64 "ssh_funcify: function ${func_name} not defined"
    }

    # Multi-stage escaping: function -> arguments -> remote command
    printf -v escaped_func_txt '%q' "${func_txt}"
    printf -v escaped_args '%q ' "${args[@]}"

    printf -v cmd 'eval %s && %s %s' \
      "${escaped_func_txt}" \
      "${func_name}" \
      "${escaped_args}"

    printf -v remote_cmd 'bash -c %q' "${cmd}"

    error_file="$(mktemp)"
  }

  errorquire_and_cleanup() {
    # Initialize error message and handle temporary error file cleanup
    # Ensures error_file is read and removed even if SSH command succeeds
    [[ -f "${error_file}" ]] && {
      error_msg=$(<"${error_file}")
      rm -f "${error_file}"
    }
  }

  perform() {
    # Execute and handle all error cases with detailed reporting
    ssh_response=$(_ssh) || {
      declare exit_code=$?
      errorquire_and_cleanup
      # pransi '93' "[${exit_code}] ${ssh_response}"

      # Map exit codes to meaningful error messages
      case ${exit_code} in
      255) # SSH connection/transport failures
        [[ -n "${error_msg}" ]] || error_msg="SSH connection failed to ${address}"
        ;;
      127) # Remote shell or command execution issues
        [[ -n "${error_msg}" ]] || error_msg="Remote shell not available"
        ;;
      *) # Function-specific failures
        [[ -n "${error_msg}" ]] || error_msg="Function ${func_name} failed with code ${exit_code}"
        ;;
      esac

      [[ -n "${ssh_response}" ]] && echo "${ssh_response}"
      fail "${exit_code}" "ssh_funcify: ${error_msg}"
    }

    echo "${ssh_response}"
    errorquire_and_cleanup
    return 0
  }

  _ssh() {
    # Non-interactive SSH with strict timeout and disabled host checking
    ssh \
      -o LogLevel=ERROR \
      -o UserKnownHostsFile=/dev/null \
      -o StrictHostKeyChecking=no \
      -o BatchMode=yes \
      -o ConnectTimeout=10 \
      "${address}" \
      "${remote_cmd}" 2>"${error_file}"
  }

  prepare
  perform
}
