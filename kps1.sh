#!/bin/bash

__KPS1=""
__KPS1_KUBECONFIG="$HOME/.kube/config"
__KPS1_KUBECONFIG_DIR="$HOME/.kube/config.d"

# color codes
__KPS1_COLOR_MAGENTA="\e[35m"
__KPS1_COLOR_CYAN="\e[36m"
__KPS1_COLOR_END="\e[0m"

__kps1_kubectl() {
  kubectl --kubeconfig="${__KPS1_KUBECONFIG}" $@
}

__kps1_init() {
  local context=$(yq '.contexts[0].name' $HOME/.kube/config)
  local namespace=$(yq '.contexts[0].context.namespace // "default"' ${__KPS1_KUBECONFIG})

  __kps1_set_all $context $namespace
}

__kps1_get_context() {
  # printf "${__KPS1}" | cut -f1 -d':'
  local context=(${__KPS1//:/ })
  printf ${context[0]}
}
__kps1_get_namespace() {
  # printf "${__KPS1}" | cut -f2 -d':'
  local context=(${__KPS1//:/ })
  printf ${context[1]}
}
__kps1_set_all() {
  __KPS1="${1}:${2}"
}
__kps1_set_context() {
  local namespace=$(__kps1_get_namespace)
  __KPS1="${1}:${namespace}"
}
__kps1_set_namespace() {
  local context=$(__kps1_get_context)
  __KPS1="${context}:${1}"
}
__kps1_set_kubeconfig() {
  __KPS1_KUBECONFIG=${1}
}

__kps1_ps1() {
  echo -e "(${__KPS1_COLOR_CYAN}$(__kps1_get_context)${__KPS1_COLOR_END}:${__KPS1_COLOR_MAGENTA}$(__kps1_get_namespace)${__KPS1_COLOR_END})"
}

__kps1_switch_context() {
  local kubeconfig=$(ls -p $__KPS1_KUBECONFIG_DIR | grep -v / | fzf --no-sort)
  if [[ -z "$kubeconfig" ]]; then
    return
  fi
  __kps1_set_kubeconfig "$__KPS1_KUBECONFIG_DIR/$kubeconfig"

  local context=$(yq '.contexts[0].name' $__KPS1_KUBECONFIG_DIR/$kubeconfig)
  local namespace=$(yq '.contexts[0].context.namespace // "default"' $HOME/.kube/config.d/$kubeconfig)

  __kps1_set_all $context $namespace
}

__kps1_switch_namespace() {
  local ns=$(__kps1 get namespace -o name | cut -f2 -d'/' | fzf)
  if [[ -z "${ns}" ]]; then
    return
  fi
  (kubectl --kubeconfig "${__KPS1_KUBECONFIG}" config set-context --current --namespace="${ns}" > /dev/null &)

  # update namespace
  __kps1_set_namespace "${ns}"
}

__kps1_init
