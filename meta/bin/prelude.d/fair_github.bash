# This file should be sourced, not run

function repo_url() {
  repo=${1:-}
  [[ -n $repo ]] || return 1

  [[ $repo =~ / ]] || repo="fairpm/$repo"
  [[ $repo =~ : ]] || repo="git@github.com:$repo"
  echo "$repo"
}