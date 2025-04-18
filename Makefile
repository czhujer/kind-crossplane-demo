# Set environment variables
export CLUSTER_NAME?=crossplane-demo
export CILIUM_VERSION?=1.17.3

# kind image list
export KIND_NODE_IMAGE="kindest/node:v1.32.2@sha256:f226345927d7e348497136874b6d207e0b32cc52154ad8323129352923a3142f"

.PHONY: kind-basic
kind-basic: kind-create kx-kind kind-install-crds cilium-install

.PHONY: kind-create
kind-create:
	kind --version
	kind create cluster --name "$(CLUSTER_NAME)" \
 		--config="kind/kind-config.yaml" \
 		--image="$(KIND_NODE_IMAGE)" \
 		--retain
# for more control planes, but no workers
#	kubectl taint nodes --all node-role.kubernetes.io/master- || true

.PHONY: kind-delete
kind-delete:
	kind delete cluster --name $(CLUSTER_NAME)

.PHONY: kx-kind
kx-kind:
	kind export kubeconfig --name $(CLUSTER_NAME)

.PHONY: kind-install-crds
kind-install-crds:
	# fix prometheus-operator's CRDs
	kubectl apply -f https://raw.githubusercontent.com/prometheus-community/helm-charts/refs/heads/main/charts/kube-prometheus-stack/charts/crds/crds/crd-servicemonitors.yaml

.PHONY: cilium-install
cilium-install:
	# Add the Cilium repo
	helm repo add cilium https://helm.cilium.io/
	# install/upgrade the chart
	helm upgrade --install cilium cilium/cilium --version $(CILIUM_VERSION) \
	   -f kind/kind-values-cilium.yaml \
	   -f kind/kind-values-cilium-hubble.yaml \
	   -f kind/kind-values-cilium-service-monitors.yaml \
	   --namespace kube-system \
	   --wait
