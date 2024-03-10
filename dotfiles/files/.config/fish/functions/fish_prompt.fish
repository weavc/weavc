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
  set -l dirty    (set_color red --bold)"⨯"(set_color normal)

  set -l normal_color     (set_color normal)
  set -l success_color    (set_color brgreen)
  set -l error_color      (set_color red --bold)
  set -l directory_color  (set_color green)
  set -l repository_color (set_color blue --bold)

  set -l prompt_string "$fish $normal_color"(set_color white --bold)(whoami)"$normal_color"

  if test "$theme_ignore_ssh_awareness" != 'yes' -a -n "$SSH_CLIENT$SSH_TTY"
    set prompt_string "$fish $normal_color"(set_color white --bold)(whoami)"@"(hostname -s)"$normal_color"
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

function git_is_repo -d "Check if directory is a repository"
  test -d .git
  or begin
    set -l info (command git rev-parse --git-dir --is-bare-repository 2>/dev/null)
    and test $info[2] = false
  end
end

function git_is_worktree -d "Check if directory is inside the worktree of a repository"
  git_is_repo
  and test (command git rev-parse --is-inside-git-dir) = false
end

function git_is_touched -d "Check if repo has any changes"
  git_is_worktree; and begin
    not command git diff-index --cached --quiet HEAD -- >/dev/null 2>&1
    or not command git diff --no-ext-diff --quiet --exit-code >/dev/null 2>&1
  end
end

function git_branch_name -d "Get current branch name"
  git_is_repo; and begin
    command git symbolic-ref --short HEAD 2> /dev/null;
      or command git show-ref --head -s --abbrev | head -n1 2> /dev/null
  end
end