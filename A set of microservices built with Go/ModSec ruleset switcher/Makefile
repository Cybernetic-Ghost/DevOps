REGISTRY ?= localhost:5000
NAMESPACE ?= security
APP_VERSION ?= $(shell git describe --tags --always --dirty 2>/dev/null || echo "dev")

build-nginx:
	docker build -t $(REGISTRY)/modsec-nginx:$(APP_VERSION) -f nginx/Dockerfile nginx/

build-controller:
	docker build -t $(REGISTRY)/modsec-controller:$(APP_VERSION) -f controller/Dockerfile controller/

load-images:
	kind load docker-image $(REGISTRY)/modsec-nginx:$(APP_VERSION) --name modsec-cluster
	kind load docker-image $(REGISTRY)/modsec-controller:$(APP_VERSION) --name modsec-cluster

apply-manifests:
	kubectl apply -f k8s/00-namespace.yaml
	kubectl apply -f k8s/01-configs.yaml
	kubectl apply -f k8s/02-serviceaccount.yaml
	kubectl apply -f k8s/03-deployment.yaml
	kubectl apply -f k8s/04-service.yaml
	kubectl apply -f k8s/05-ingress.yaml
	kubectl apply -f k8s/06-networkpolicy.yaml

deploy: build-nginx build-controller load-images apply-manifests

test-api:
	@echo "Testing API..."
	@API_KEY=$$(kubectl get secret controller-secrets -n $(NAMESPACE) -o jsonpath='{.data.API_KEY}' | base64 -d)
	@echo "API Key: $$API_KEY"
	curl -v -H "X-API-Key: $$API_KEY" http://localhost/modsecurity/mode

setup-registry:
	@echo "Setting up local registry..."
	kubectl apply -f https://raw.githubusercontent.com/kubernetes/kubernetes/HEAD/test/images/registry/registry.yaml
	kubectl rollout status deployment/registry -n kube-system --timeout=90s
	kubectl port-forward svc/registry -n kube-system 5000:5000 &
	sleep 5

.PHONY: build-nginx build-controller load-images apply-manifests deploy test-api setup-registry