# Set environment variables
export CLUSTER_NAME?=crossplane-demo
export CILIUM_VERSION?=1.17.3
export ARGOCD_CHART_VERSION=7.8.26

# kind image list
export KIND_NODE_IMAGE="kindest/node:v1.32.2@sha256:f226345927d7e348497136874b6d207e0b32cc52154ad8323129352923a3142f"

.PHONY: kind-basic
kind-basic: kind-create kx-kind kind-install-crds cloud-controller cilium-install argocd-deploy metrics-server-deploy prometheus-stack-deploy

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

# .PHONY: metallb-deploy
# metallb-deploy:
# 	kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.12.1/manifests/namespace.yaml
# 	kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.14.9/config/manifests/metallb-native.yaml

.PHONY: kind-install-crds
kind-install-crds:
	# fix prometheus-operator's CRDs
	kubectl apply -f https://raw.githubusercontent.com/prometheus-community/helm-charts/refs/heads/main/charts/kube-prometheus-stack/charts/crds/crds/crd-servicemonitors.yaml
	# Gateway API (needed for Cilium with enabled gateway-controller)
	kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.2.0/standard-install.yaml
	kubectl apply -f https://raw.githubusercontent.com/kubernetes-sigs/gateway-api/v1.2.0/config/crd/experimental/gateway.networking.k8s.io_tlsroutes.yaml

.PHONY: cloud-controller
cloud-controller:
	go install sigs.k8s.io/cloud-provider-kind@latest
	sudo ~/go/bin/cloud-provider-kind

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
	# for upgrade
	# kubectl -n kube-system rollout restart deployment/cilium-operator
	# kubectl -n kube-system rollout restart ds/cilium

.PHONY: argocd-deploy
argocd-deploy:
	helm repo add argo https://argoproj.github.io/argo-helm
	helm upgrade --install \
		argocd-single \
		argo/argo-cd \
		--namespace argocd \
		--create-namespace \
		--version "${ARGOCD_CHART_VERSION}" \
		-f kind/kind-values-argocd.yaml \
		-f kind/kind-values-argocd-service-monitors.yaml \
		--wait
	# kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo ""

.PHONY: metrics-server-deploy
metrics-server-deploy:
	kubectl apply -f argocd/projects/system-kube.yaml
	kubectl apply -f argocd/metrics-server.yaml

.PHONY: prometheus-stack-deploy
prometheus-stack-deploy:
	# create namespace with annotations for PSS/PSA
	kubectl apply -f k8s-manifests/namespace-monitoring.yaml
	# projects
	kubectl apply -f argocd/projects/system-monitoring.yaml
	# CRDs
	kubectl apply -f argocd/prometheus-operator-crds.yaml
	# apps
	kubectl apply -f argocd/prometheus-stack.yaml
	kubectl apply -f argocd/prometheus-adapter.yaml

.PHONY: crossplane-deploy
crossplane-deploy:
	kubectl apply -f argocd/projects/system-crossplane.yaml
	kubectl apply -f argocd/crossplane.yaml
	sleep 20s
	kubectl apply -f k8s-manifests/crossplane-config-opentofu.yaml
	kubectl apply -f k8s-manifests/opentofu-workspace.yaml
