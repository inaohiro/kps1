#!/bin/bash

# oriinal kubeconfig
__KPS1_ORIGINAL_KUBECONFIG=~/.kube/config

# create temporary directory
# this directory will be removed after terminal closed
__KPS1_TMP_DIR="$(mktemp -dt kubeconfig.XXXXXX)"
trap "rm -rf $__KPS1_TMP_DIR" EXIT

# for terminal isolation, create temporary kubeconfig
__KPS1_KUBECONFIG="${__KPS1_TMP_DIR}/config"
export KUBECONFIG="${__KPS1_KUBECONFIG}"

# variable for PS1
__KPS1_CONTEXT=""

# color codes
__KPS1_COLOR_MAGENTA="\e[35m"
__KPS1_COLOR_CYAN="\e[36m"
__KPS1_COLOR_END="\e[0m"

__kps1_init() {
  # copy original kubeconfig
  cp "${__KPS1_ORIGINAL_KUBECONFIG}" "${__KPS1_KUBECONFIG}"

  # get current contexts
  local context=$(kubectl config get-contexts --kubeconfig ${__KPS1_ORIGINAL_KUBECONFIG} | grep -e '\*' | tr -s ' ' | tr -d '\*')

  local cluster=$(echo $context | cut -f1 -d' ' -s)
  local namespace=$(echo $context | cut -f4 -d' ' -s)
  local namespace=${namespace:-default}

  __kps1_set_context $cluster $namespace
}

__kps1_get_context() {
  printf "${__KPS1_CONTEXT}"
}
__kps1_get_cluster() {
  # printf "${__KPS1_CONTEXT}" | cut -f1 -d':'
  local context=(${__KPS1_CONTEXT//:/ })
  printf ${context[0]}
}
__kps1_get_namespace() {
  # printf "${__KPS1_CONTEXT}" | cut -f2 -d':'
  local context=(${__KPS1_CONTEXT//:/ })
  printf ${context[1]}
}
__kps1_set_context() {
  __KPS1_CONTEXT="${1}:${2}"
}
__kps1_set_cluster() {
  local namespace=$(__kps1_get_namespace)
  __KPS1_CONTEXT="${1}:${namespace}"
}
__kps1_set_namespace() {
  local cluster=$(__kps1_get_cluster)
  __KPS1_CONTEXT="${cluster}:${1}"
}

__kps1_ps1() {
  echo -e "(${__KPS1_COLOR_CYAN}$(__kps1_get_cluster)${__KPS1_COLOR_END}:${__KPS1_COLOR_MAGENTA}$(__kps1_get_namespace)${__KPS1_COLOR_END})"
}

__kps1_switch_context() {
  # use original kubeconfig to get all contexts
  local ctx=$(kubectl config get-contexts -o name --kubeconfig ${__KPS1_ORIGINAL_KUBECONFIG} | fzf)
  if [[ -z "$ctx" ]]; then
    return
  fi

  # update context
  local kubeconfig=$(kubectl config view --flatten --merge --output json --kubeconfig ${__KPS1_ORIGINAL_KUBECONFIG} | jq -c --arg ctx $ctx '(.contexts[] | select(.name == $ctx)) as $c | {apiVersion, kind, preferences, "current-context": $ctx, contexts: [$c], clusters: [.clusters[] | select(.name == $c.context.cluster)], users: [.users[] | select(.name == $c.context.user)]}')

  (echo $kubeconfig > $__KPS1_KUBECONFIG &)
  local context=$(echo $kubeconfig | jq -c -r '[.clusters[0].name, .contexts[0].namespace // "default"] | join(" ")')
  local cluster=$(echo $context | cut -f1 -d' ' -s)
  local namespace=$(echo $context | cut -f2 -d' ' -s)

  __kps1_set_context $cluster $namespace
}

__kps1_switch_namespace() {
  local ns=$(kubectl get namespace -o name | cut -f2 -d'/' | fzf)
  if [[ -z "${ns}" ]]; then
    return
  fi

  # update namespace
  (kubectl config set-context --current --namespace="${ns}" > /dev/null &)
  __kps1_set_namespace "${ns}"
}

__kps1_init