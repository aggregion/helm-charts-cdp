Setup
=====

1. Create a namespace.
2. Create a docker registry secret in the created namespace.
On your choose. Edit and apply the file `aggregion-registry.secret.yaml`
or run the script `create-registry-secret.sh`.
```
$ bash create-registry-secret.sh {{NameSpace}} {{Username}} {{Password}} {{Hostname}} [[Email is optional]]
```
