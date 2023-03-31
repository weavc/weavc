#!/usr/bin/env bash
prompt() {
    if [ "$?" != "0" ]; then
        local arrow_color=${bold_red}
    else
        local arrow_color=${reset_color}
    fi
    if [ ! -z "${GITHUB_USER}" ]; then
        local USERNAME="@${GITHUB_USER}"
    else
        local USERNAME="\u"
    fi
    local cwd="$(pwd | sed "s|^${HOME}|~|")"
    PS1="${green}${USERNAME} ${arrow_color}➜${reset_color} ${bold_blue}${cwd}${reset_color} $(scm_prompt_info)${white}$ ${reset_color}"
    
    # Prepend Python virtual env version to prompt
    if [[ -n $VIRTUAL_ENV ]]; then
        if [ -z "${VIRTUAL_ENV_DISABLE_PROMPT:-}" ]; then
            PS1="(`basename \"$VIRTUAL_ENV\"`) ${PS1:-}"
        fi
    fi
}

SCM_THEME_PROMPT_PREFIX="${reset_color}${cyan}(${bold_red}"
SCM_THEME_PROMPT_SUFFIX="${reset_color} "
SCM_THEME_PROMPT_DIRTY=" ${bold_yellow}✗${reset_color}${cyan})"
SCM_THEME_PROMPT_CLEAN="${reset_color}${cyan})"
SCM_GIT_SHOW_MINIMAL_INFO="true"
safe_append_prompt_command prompt
