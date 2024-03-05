---
layout: post
title: Fish Prompt Configuration
description: 'Prompt configuration for fish'
terms: ['dev', 'linux']
icon: code-slash
sort_key: 1
---

```bash
# You can override some default options with config.fish:
#
#  set -g theme_short_path yes
#  set -g theme_stash_indicator yes
#  set -g theme_ignore_ssh_awareness yes

function fish_prompt
  set -l last_command_status $status
  set -g fish_prompt_pwd_full_dirs 100
  set -l cwd

  if test "$theme_short_path" = 'yes'
    set cwd (basename (prompt_pwd))
  else
    set cwd (prompt_pwd)
  end


  set -l fish     "⋊>"
  set -l ahead    "↑"
  set -l behind   "↓"
  set -l diverged "⥄"
  set -l dirty    (set_color red --bold)"⨯"(set_color normal)
  set -l stash    "≡"
  set -l none     "◦"

  set -l normal_color     (set_color normal)
  set -l success_color    (set_color brgreen)
  set -l error_color      (set_color red --bold)
  set -l directory_color  (set_color green)
  set -l repository_color (set_color blue --bold)

  set -l prompt_string "$fish $normal_color"(set_color white --bold)(whoami)"$normal_color"

  if test "$theme_ignore_ssh_awareness" != 'yes' -a -n "$SSH_CLIENT$SSH_TTY"
    set prompt_string "$fish "(hostname -s)" $fish"
  end

  if test $last_command_status -eq 0
    echo -n -s $success_color $prompt_string $normal_color
  else
    echo -n -s $error_color $prompt_string $normal_color
  end

  if git_is_repo
    if test "$theme_short_path" = 'yes'
      set root_folder (command git rev-parse --show-toplevel 2> /dev/null)
      set parent_root_folder (dirname $root_folder)
      set cwd (echo $PWD | sed -e "s|$parent_root_folder/||")
    end

    echo -n -s " " $directory_color $cwd $normal_color
    if git_is_touched
      echo -n -s " ("$repository_color (git_branch_name) $normal_color " " $dirty") "
    else
      echo -n -s " ("$repository_color (git_branch_name) $normal_color") "
    end
  else
    echo -n -s " " $directory_color $cwd $normal_color " " 
  end
end

function fish_right_prompt
  set_color $fish_color_autosuggestion 2> /dev/null; or set_color 555
  date "+%H:%M:%S"
  set_color normal
end

```
