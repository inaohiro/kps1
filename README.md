# kps1

kps1 is Kubernetes prompt for bash, and provides a way to switch contexts and namespaces.

## Requirements

- fzf
- jq

## Installation

1. Download kps1.sh

  ```bash
  curl -o ~/.kps1.sh -L https://raw.githubusercontent.com/inaohiro/kps1/main/kps1.sh
  ```

2. Edit .bashrc

  ```bash
  test -f .kps1.sh && source .kps1.sh
  export PS1='[\u@\h \W] `__kps1_ps1` \n$ '
  alias kc="__kps1_switch_context"
  alias kn="__kps1_switch_namespace"
  ```