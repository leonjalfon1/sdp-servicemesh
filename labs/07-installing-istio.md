# LAB 07: Installing Istio

## Description

In this lab we will install Istio in our GKE cluster

## Instructions

1. Let's use gcloud CLI to configure kubectl and get access to the cluster (it will be recreated after finish with linkerd)

```
gcloud container clusters get-credentials $(hostname) --zone $(gcloud compute instances list $(hostname) --format "value(zone)") --project devops-course-architecture
```

---

2. Test the kubectl configuration by running the following command

```
kubectl get nodes
```

---

3. Set the version to download (we will use 1.8.0):

```
echo 'export ISTIO_VERSION="1.8.0"' >> ${HOME}/.bash_profile
source ${HOME}/.bash_profile
echo ${ISTIO_VERSION}
```

--

4. Download istioctl

```
curl -L https://istio.io/downloadIstio | sh -
```

---

5. Add to istioctl to the path

```
echo 'export PATH="$PATH:/home/sela/istio-1.8.0/bin"' >> ${HOME}/.bash_profile
source ${HOME}/.bash_profile
```

---

6. Ensure istioctl was installed successfully

```
istioctl version --remote=false
```

---

7. Begin the Istio pre-installation check by running

```
istioctl x precheck
```

---

8. Install istio components using the "Demo" profile

```
istioctl install --set profile=demo -y
```

- Note: The profiles provide customization of the Istio control plane and of the sidecars for the Istio data plane. For more info see: https://istio.io/latest/docs/setup/additional-setup/config-profiles/

---

9. Verify that the services have been deployed using
```
kubectl get svc -n istio-system
```

---

10. Check the corresponding pods with the following command
```
kubectl get pods -n istio-system
```

---

11. Prepare the manifests to verify the installation

```
istioctl manifest generate --set profile=demo > $HOME/generated-manifest.yaml
```

---

12. Then run the following verify-install command to see if the installation was successful

```
istioctl verify-install -f $HOME/generated-manifest.yaml
```

---

13. Install the istio addons for observability

```
kubectl apply -f $HOME/istio-1.8.0/samples/addons/prometheus.yaml
```
```
kubectl apply -f $HOME/istio-1.8.0/samples/addons/grafana.yaml
```
```
kubectl apply -f $HOME/istio-1.8.0/samples/addons/jaeger.yaml
```
```
kubectl apply -f $HOME/istio-1.8.0/samples/addons/kiali.yaml
```

- Note: you may have to run the kiali command above twice, it may fail due to dependency issues

---

14. Expose the addons applications to allow access from outside the cluster

```
kubectl patch svc kiali -p '{"spec": {"type": "LoadBalancer"}}' -n istio-system
```
```
kubectl patch svc prometheus -p '{"spec": {"type": "LoadBalancer"}}' -n istio-system
```
```
kubectl patch svc tracing -p '{"spec": {"type": "LoadBalancer"}}' -n istio-system
```
```
kubectl patch svc grafana -p '{"spec": {"type": "LoadBalancer"}}' -n istio-system
```
