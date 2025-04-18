# kind-crossplane-demo

## versions
- https://github.com/kubernetes-sigs/kind/releases
- https://github.com/cilium/cilium/releases
- https://artifacthub.io/packages/helm/argo/argo-cd

## cilium
if you want to use ingress-controller, you will need cloud-controller..

use https://kind.sigs.k8s.io/docs/user/loadbalancer/
    - $ sudo ~/go/bin/cloud-provider-kind

or metallb https://medium.com/groupon-eng/loadbalancer-services-using-kubernetes-in-docker-kind-694b4207575d

(check makefile)

# links
- https://github.com/kubernetes-sigs/kind/releases
- https://github.com/vfarcic/crossplane-tutorial/
- https://docs.cilium.io/en/v1.17/network/servicemesh/gateway-api/gateway-api/
- https://docs.cilium.io/en/stable/network/servicemesh/ingress/
- https://medium.com/@eleni.grosdouli/argocd-deployment-on-rke2-with-cilium-gateway-api-ab1769cc28a3

## kind cloud controller


## ✅ [cilium-test-1] All 67 tests (272 actions) successful, 45 tests skipped, 0 scenarios skipped.
## ❌ 1/67 tests failed (1/272 actions), 45 tests skipped, 0 scenarios skipped:
