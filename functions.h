_printfl()
{   #print lines
    _printfl_var_max_len="80"
    if [ -n "${1}" ]; then
        _printfl_var_word_len="$((${#1} + 2))"
        _printfl_var_sub="$((${_printfl_var_max_len} - ${_printfl_var_word_len}))"
        _printfl_var_half="$((${_printfl_var_sub} / 2))"
        _printfl_var_other_half="$((${_printfl_var_sub} - ${_printfl_var_half}))"
        printf "%b" "\033[1m" #white strong
        printf '%*s' "${_printfl_var_half}" '' | tr ' ' -
        printf "%b" "\033[7m" #white background
        printf " %s " "${1}"
        printf "%b" "\033[0m\033[1m" #white strong
        printf '%*s' "${_printfl_var_other_half}" '' | tr ' ' -
        printf "%b" "\033[0m" #back to normal
        printf "\\n"
    else
        printf "%b" "\033[1m" #white strong
        printf '%*s' "${_printfl_var_max_len}" '' | tr ' ' -
        printf "%b" "\033[0m" #back to normal
        printf "\\n"
    fi
}

_printfs()
{   #print step
    [ -z "${1}" ] && return 1
    printf "%s\\n" "[+] ${*}"
}

_die()
{
    [ -z "${1}"] && return 1
    printf "%b\\n" "[-] Error: ${*}"
    exit 1
}

_header()
{
    clear
    _printfl "Kernel ck builder (${patchkernel})"
    printf "%b\\n" "\033[1m Updates:\033[0m     https://github.com/chilicuil/learn/blob/master/sh/is/kernel-ck-ubuntu"
    printf "%b\\n" "\033[1m Patches:\033[0m     -bfq,"
    _printfl "Current configuration: edit the script to change it"
    printf "%s\\n" "  build path:        ${tmp_path}"
    printf "%s\\n" "  kernel:            ${patchkernel}"
    printf "%s\\n" "  -bfq patchset:     ${bfq}"
    printf "%s\\n" "  arch:              ${arqt}"
    printf "%s\\n" "  concurrency level: ${cl}"
    _printfl
}

_cmd()
{   #print current command, exits on fail
    [ -z "${1}" ] && return 0

    printf "%s " "    $ ${@}"
    printf "%s\\n"
    eval "${@}" 2>&1 >/tmp/kernel-ck-ubuntu.error

    status="${?}"
    [ X"${status}" != X"0" ] && {        \
        cat /tmp/kernel-ck-ubuntu.error; \
        exit "${status}"; } || return
}

_cmdsudo()
{   #print current command, exits on fail
    [ -z "${1}" ] && return 0

    printf "%s " "    $ sudo ${@}"
    printf "%s\\n" "${sudopwd}" | ${sudocmd} ${@} 2>&1 >/tmp/kernel-ck-ubuntu.error

    status="${?}"
    [ X"${status}" != X"0" ] && {        \
        cat /tmp/kernel-ck-ubuntu.error; \
        exit "${status}"; } || return
}

_animcui()
{   #wait animation
    [ -z "${1}" ] && { printf "%5s\n" ""; return 1; }

    if ! printf "%s" "$(pidof "${1}")" | grep "[0-9].*" >/dev/null; then
        printf "%5s\n" ""
        return 1;
    fi

    _animcui_var_animation_state="1"

    if [ ! "$(ps -p "$(pidof "${1}")" -o comm= 2>/dev/null)" ]; then
        printf "%5s\n" ""
        return 1
    fi

    printf "%5s" ""

    while [ "$(ps -p "$(pidof "${1}")" -o comm= 2>/dev/null)" ]; do
        printf "%b" "\b\b\b\b\b"
        case "${_animcui_var_animation_state}" in
            1) printf "%s" '\o@o\'
               _animcui_var_animation_state="2" ;;
            2) printf "%s" '|o@o|'
               _animcui_var_animation_state="3" ;;
            3) printf "%s" '/o@o/'
               _animcui_var_animation_state="4" ;;
            4) printf "%s" '|o@o|'
               _animcui_var_animation_state="1" ;;
        esac
        sleep 1
    done
    printf "%b" "\b\b\b\b\b" && printf "%5s\n" ""
}

_getroot()
{   #get sudo's password, define $sudopwd and $sudocmd
    if [ ! X"${LOGNAME}" = X"root" ]; then
        printf "%s\\n" "Detecting user ${LOGNAME} (non-root) ..."
        printf "%s\\n" "Checking if sudo is available ..."

        if command -v "sudo" >/dev/null 2>&1; then
            sudo -K

            if [ -n "${sudopwd}" ]; then
                # password check
                _getroot_var_test="$(printf "%s\\n" "${sudopwd}" | sudo -S ls 2>&1)"
                _getroot_var_status="${?}"
                _getroot_var_not_allowed="$(printf "%s" "${_getroot_var_test}" | \
                                         grep -i "sudoers")"

                if [ -n "${_getroot_var_not_allowed}" ]; then
                    printf "%s %s\\n" "You're not allowed to use sudo," \
                    "get in contact with your local administrator"
                    exit
                fi

                if [ X"${_getroot_var_status}" != X"0" ]; then
                    sudopwd=""
                    printf "%s\\n" "Incorrect preseed password"
                    exit
                else
                    sudocmd="sudo -S"
                fi
                printf "%s\\n" "    - all set ..."
                return
            fi

            i=0 ; while [ "${i}" -lt "3" ]; do
                i="$((${i} + 1))"
                printf "%s" "   - enter sudo password: "
                stty -echo
                read sudopwd
                stty echo

                # password check
                _getroot_var_test="$(printf "%s\\n" "${sudopwd}" | sudo -S ls 2>&1)"
                _getroot_var_status="${?}"
                _getroot_var_not_allowed="$(printf "%s" "${_getroot_var_test}" | \
                                         grep -i "sudoers")"

                if [ -n "${_getroot_var_not_allowed}" ]; then
                    printf "\\n%s %s\\n" "You're not allowed to use sudo," \
                    "get in contact with your local administrator"
                    exit
                fi

                printf "\\n"
                if [ X"${_getroot_var_status}" != X"0" ]; then
                    sudopwd=""
                else
                    sudocmd="sudo -S"
                    break
                fi
            done

            if [ -z "${sudopwd}" ]; then
                printf "%s\\n" "Failed authentication"
                exit
            fi
        else
            printf "%s %s\\n" "You're not root and sudo isn't available." \
            "Please run this script as root!"
            exit
        fi
    fi
}

_cleanup()
{
    stty echo
    printf "\\n"
    _printfl "Cleanup"
    _printfs "deleting files at ${tmp_path} ..."
    printf "%s\\n" "${sudopwd}" | _cmd ${sudocmd} rm -rf "${tmp_path}/linux-${patchkernel}-${bfq}"
    [ -z "${1}" ] && exit
}

_waitfor()
{   #print, execute and wait for a command to finish
    [ -z "${1}" ] && return 1

    printf "%s " "    $ ${@} ..."
    ${@} > /dev/null 2>&1 &
    sleep 1s

    _animcui "${1}"
}

_waitforsudo()
{   #print, execute and wait for a command to finish
    [ -z "${1}" ] && return 1

    printf "%s " "    $ sudo ${@} ..."
    printf "%s\\n" "${sudopwd}" | ${sudocmd} ${*} >/dev/null 2>&1 &
    sleep 1s

    if [ X"${1}" = X"DEBIAN_FRONTEND=noninteractive" ]; then
        _animcui "${2}"
    else
        _animcui "${1}"
    fi
}
