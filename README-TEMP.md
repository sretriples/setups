# Upgrade Tanzu Kubernetes Grid Management - Kube-VIP

---

## :construction: EM CONSTRUCAO :construction:

## Introdução

Este documento descreve o processo de upgrade do Tanzu Kubernetes Grid Management (TKGm) da versão 2.5.3 para 2.5.4. Essa atualização é classificada como um patch upgrade, focado em correções de bugs, melhorias de estabilidade e atualizações de segurança. Por se tratar de uma atualização incremental dentro da mesma série 2.5.x, a operação é simples e normalmente não exige alterações de infraestrutura, templates de VM ou configurações de rede.

O processo segue as recomendações da documentação oficial da Broadcom para TKG 2.5 e envolve essencialmente a atualização do Tanzu CLI, sincronização de plugins e execução do comando de upgrade do Management Cluster.

### 📌 Pré-requisitos (específicos para 2.5.3 → 2.5.4)

✔️ Versões e Ferramentas

✔️ Ter acesso aos binários do Tanzu CLI 2.5.4.

✔️ Ter o kubectl configurado e conectado ao management cluster 2.5.3.


### 🚀 Passo a passo para o Upgrade 2.5.3 → 2.5.4

1 - Acesse a VM Bootstrap (Bastion)

2 - Execute o script abaixo, com permissão administrativa, para atualização e instalação de ferramentas necessárias

```bash
curl -fsSL https://raw.githubusercontent.com/sretriples/setups/refs/heads/main/tkgm-bastion.sh | bash
```
3 - 


```bash
kubectl get cluster tkg-management -n tkg-system -o yaml | grep TKGVERSION
```

```bash
#Resultado
kubectl get cluster tkg-management -n tkg-system -o yaml | grep TKGVERSION
TKGVERSION: v2.5.3
```



```bash
# Remover variaveis
unset VSPHERE_DATACENTER
unset VSPHERE_DATASTORE
unset VSPHERE_FOLDER
unset VSPHERE_NETWORK
unset VSPHERE_RESOURCE_POOL
```

```bash
## Ralizar o backup para /TKGm/dc02/management/bkp/
cp -R ~/.config/ /TKGm/dc02/management/bkp/

# Excluir o arquivo tkg-compatibility.yaml
rm -f ~/.config/tanzu/tkg/compatibility/tkg-compatibility.yaml
```

```bash
# Execução do script
tanzu plugin search -n management-cluster --show-details
```

```bash
# Backup Pinniped Secret
kubectl get secret -n tkg-system tkg-management-dr-pinniped-package -oyaml > ./bkp/tkg-management-dr-pinniped-package.yaml
```

```bash
# Atualizacao do Management Cluster
tanzu mc upgrade --timeout 60m0s --vsphere-vm-template-name "/VxRail-Datacenter/vm/tkgm-management/photon-5-kube-v1.29.15+vmware.1"
```

```bash
Upgrading management cluster 'tkg-management-dr' to TKG version 'v2.5.4' with Kubernetes version 'v1.29.15+vmware.1'. Are you sure? [y/N]: y
Validating the compatibility before management cluster upgrade
Validating for the user configuration secret to be existed in the cluster
Warning: unable to find component 'kube_rbac_proxy' under BoM
Warning: unable to find component 'aad-pod-identity' under BoM
Upgrading management cluster providers...
current TKG version is 2.5.4 >= 2.5.0, AWS and Azure providers support has been discontinued since TKG v2.5.0.
Checking if cert-manager needs upgrade...
Cert-manager is already up to date
Performing upgrade...
Scaling down Provider={"name":"cluster-api","namespace":"capi-system"} providerVersion=""
Scaling down Provider={"name":"bootstrap-kubeadm","namespace":"capi-kubeadm-bootstrap-system"} providerVersion=""
Scaling down Provider={"name":"control-plane-kubeadm","namespace":"capi-kubeadm-control-plane-system"} providerVersion=""
Scaling down Provider={"name":"infrastructure-vsphere","namespace":"capv-system"} providerVersion=""
Scaling down Provider={"name":"ipam-in-cluster","namespace":"caip-in-cluster-system"} providerVersion=""
Deleting Provider={"name":"cluster-api","namespace":"capi-system"} providerVersion=""
Capabilities API in run API group is deprecated, use Capabilities API in core API group
Installing provider="cluster-api" version="v1.10.1" targetNamespace="capi-system"
Deleting Provider={"name":"bootstrap-kubeadm","namespace":"capi-kubeadm-bootstrap-system"} providerVersion=""
Capabilities API in run API group is deprecated, use Capabilities API in core API group
Installing provider="bootstrap-kubeadm" version="v1.10.1" targetNamespace="capi-kubeadm-bootstrap-system"
Deleting Provider={"name":"control-plane-kubeadm","namespace":"capi-kubeadm-control-plane-system"} providerVersion=""
Capabilities API in run API group is deprecated, use Capabilities API in core API group
Installing provider="control-plane-kubeadm" version="v1.10.1" targetNamespace="capi-kubeadm-control-plane-system"
Deleting Provider={"name":"infrastructure-vsphere","namespace":"capv-system"} providerVersion=""
Capabilities API in run API group is deprecated, use Capabilities API in core API group
Installing provider="infrastructure-vsphere" version="v1.13.0" targetNamespace="capv-system"
Deleting Provider={"name":"ipam-in-cluster","namespace":"caip-in-cluster-system"} providerVersion=""
Capabilities API in run API group is deprecated, use Capabilities API in core API group
Installing provider="ipam-in-cluster" version="v1.0.1" targetNamespace="caip-in-cluster-system"
Management cluster providers upgraded successfully...
Preparing addons manager for upgrade
Upgrading kapp-controller...
Adding last-applied annotation on kapp-controller...
Removing old management components...
Upgrading management components...
ℹ   Updating package repository 'tanzu-management'
ℹ   Getting package repository 'tanzu-management'
ℹ   Validating provided settings for the package repository
ℹ   Updating package repository resource
ℹ   Waiting for 'PackageRepository' reconciliation for 'tanzu-management'
ℹ   'PackageRepository' resource install status: ReconcileSucceeded
ℹ  Updated package repository 'tanzu-management' in namespace 'tkg-system'
ℹ   Installing package 'tkg.tanzu.vmware.com'
ℹ   Updating package 'tkg-pkg'
ℹ   Getting package install for 'tkg-pkg'
ℹ   Getting package metadata for 'tkg.tanzu.vmware.com'
ℹ   Updating secret 'tkg-pkg-tkg-system-values'
ℹ   Updating package install for 'tkg-pkg'
ℹ   Waiting for 'PackageInstall' reconciliation for 'tkg-pkg'
ℹ   'PackageInstall' resource install status: ReconcileSucceeded


ℹ  Updated installed package 'tkg-pkg'
Checking Tkr v1.29.15---vmware.1-tkg.1 is ready...
Checking Tkr v1.29.15---vmware.1-tkg.1 package is installed successfully...
Upgrading the runtime-extension...
Installing the default ClusterClass...
Cleanup core packages repository...
Core package repository not found, no need to cleanup
Upgrading management cluster kubernetes version...
Upgrading kubernetes cluster to `v1.29.15+vmware.1` version, tkr version: `v1.29.15+vmware.1-tkg.1`, ClusterClass: tkg-vsphere-default-v1.2.0
Constructing patch string for vsphere cluster. vsphereTemplate = /VxRail-Datacenter/vm/tkgm-management/photon-5-kube-v1.29.15+vmware.1
Patch string constructed for cluster to upgrade to tkr version: `v1.29.15+vmware.1-tkg.1`, ClusterClass: tkg-vsphere-default-v1.2.0, vpshere template: /VxRail-Datacenter/vm/tkgm-management/photon-5-kube-v1.29.15+vmware.1
Waiting for kubernetes version to be updated for control plane nodes...
waiting for kubernetes version v1.29.15+vmware.1 update
Waiting for kubernetes version to be updated for worker nodes...
waiting for kubernetes version v1.29.15+vmware.1 update
management cluster is opted out of telemetry - skipping telemetry image upgrade
Creating tkg-bom versioned ConfigMaps...
Management cluster 'tkg-management' successfully upgraded to TKG version 'v2.5.4' with kubernetes version 'v1.29.15+vmware.1'
```

```bash
tanzu cluster list --include-management-cluster -A
  NAME                  NAMESPACE             STATUS   CONTROLPLANE  WORKERS  KUBERNETES         ROLES       PLAN  TKR
  tkg-management-dr     tkg-system            running  3/3           3/3      v1.29.15+vmware.1  management  prod  v1.29.15---vmware.1-tkg.1
  tkgm-hml-sis          tkgm-hml-sis          running  3/3           2/2      v1.28.15+vmware.6  <none>      dev   v1.28.15---vmware.6-tkg.1
  tkgm-prd-big          tkgm-prd-big          running  3/3           5/5      v1.28.15+vmware.6  <none>      dev   v1.28.15---vmware.6-tkg.1
  tkgm-prd-mkt          tkgm-prd-mkt          running  3/3           4/4      v1.28.15+vmware.6  <none>      dev   v1.28.15---vmware.6-tkg.1
  tkgm-prd-sis          tkgm-prd-sis          running  3/3           2/2      v1.28.15+vmware.6  <none>      dev   v1.28.15---vmware.6-tkg.1
```

```bash
tanzu management-cluster kubeconfig get --admin ./bkp/kube-config-tkg-management
```

### 🚀 Upgrade Cluster Tanzu Kubernetes Grid 

```bash
tanzu cluster upgrade tkgm-hml-sistemas-dr --namespace tkgm-hml-sis --timeout 60m0s --vsphere-vm-template-name "/VxRail-Datacenter/vm/tkgm-management/photon-5-kube-v1.29.15+vmware.1"
```

```bash
tanzu cluster kubeconfig get tkgm-hml-sis --namespace tkgm-hml-sis --admin > /TKGm/dc02/tkg/hml-sis/tkgm-hml-sis-config
```

```bash

```
---

### Equipe responsável pela Documentação:

| Autor(es)/Revisor(es)| Atividade(s) |
| --- | --- |
| Delson Lopes | Criação da Documentação |
|  | Revisão da Documentação |