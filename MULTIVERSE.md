# machine.multiverse

Consult the [multiverse documentation](https://multiverse.service.sugarcrm.com/) to learn how to develop for multiverse. This playbook attempts to automate as much of the setup as possible.

## execute playbook

```shell
cd "$HOME/github.com/glevine/machine"

ansible-playbook -K multiverse.yml
```

## wrap up

```shell
brew doctor
```

Follow suggestions by Homebrew.

Learn how to [debug Go programs](https://multiverse.service.sugarcrm.com/development/go/#debugging) locally and remotely.

## quay.io

Log into the quay.io Docker registry. [Read the multiverse docs](https://multiverse.service.sugarcrm.com/getting_started/tooling/#dockerized-tooling) for more information.

```shell
docker login quay.io
```

## minikube

Tell minikube about the quay.io registry.

```shell
minikube addons configure registry-creds # Enter your credentials for our private docker registry quay.io.
minikube addons enable registry-creds
```

Use `minikube addons list` to see the statues of minikube addons.

[Forward a local port to a port on the pod](https://kubernetes.io/docs/tasks/access-application-cluster/port-forward-access-application-cluster/#forward-a-local-port-to-a-port-on-the-pod) to use localhost instead of `minikube ip`.

## aws

Configure the [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-configure.html).

```shell
aws configure --profile you@sugarcrm.com
AWS Access Key ID [None]: ?
AWS Secret Access Key [None]: ?
Default region name [None]: us-east-1
Default output format [None]: json
```
