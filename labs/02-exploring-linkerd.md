# LAB 02: Exploring Linkerd

## Description

In this lab we will deploy a demo application and explore Linkerd 

## Instructions

1. We can access the dashboard using the Linkerd CLI

```
linkerd dashboard &
```

- Note: Since we are working through the workstation we cannot directly access the dashboard (however you can test the access using curl)

---

2. Let's expose the dashboard service to allow access from everywhere

```
kubectl patch svc linkerd-web -p '{"spec": {"type": "LoadBalancer"}}' -n linkerd
```

---

3. Wait until the load balancer service receives the external IP

```
kubectl get svc linkerd-web -n linkerd --watch
```

---

4. Browse to the dashboard from your browser

```
https://<service-external-ip>:8084
```

- Note: To prevent DNS-rebinding attacks, the dashboard rejects any request whose Host header is not localhost, 127.0.0.1 or the service name linkerd-web.linkerd.svc

---

5. Let's disable the security mechanism for accessing the dashboard (not recommended)

```
kubectl edit deploy linkerd-web -n linkerd
```
```
--> Update the "-enforced-host" parameter to an empty string

Replace: - -enforced-host=^(localhost|127\.0\.0\.1|linkerd-web\.linkerd\.svc\.cluster\.local|linkerd-web\.linkerd\.svc|\[::1\])(:\d+)?$
With: - -enforced-host=

apiVersion: apps/v1
kind: Deployment
metadata:
  name: linkerd-web
spec:
  template:
    spec:
      containers:
        - name: web
          args:
            - -api-addr=linkerd-controller-api.linkerd.svc.cluster.local:8085
            - -grafana-addr=linkerd-grafana.linkerd.svc.cluster.local:3000
            - -controller-namespace=linkerd
            - -log-level=info
            - -enforced-host=
```

---

4. Browse to the dashboard again (the rolling update may take a few seconds to complete)

```
https://<service-external-ip>:8084
```

---

5. Install the app (not meshed)

```
kubectl apply -f https://raw.githubusercontent.com/leonjalfon1/sdp-servicemesh/main/resources/emojivoto-app.yaml
```

- Note: to see the manifests run

```
curl https://raw.githubusercontent.com/leonjalfon1/sdp-servicemesh/main/resources/emojivoto-app.yaml
```

---

6. Before adding Linkerd to the emojivoto app, let's inspect the configuration of the web service pod

```
kubectl -n emojivoto get pods -l app=web-svc -o yaml
```

- Note: Currently it have a pod with a single container

---

7. Let's add Linkerd to emojivoto by running

```
kubectl get -n emojivoto deploy -o yaml \
  | linkerd inject - \
  | kubectl apply -f -
```

---

8. Then, let's ispect the configuration of the web service again

```
kubectl -n emojivoto get pods -l app=web-svc -o yaml
```

- Note: The linkerd sidecar was injected

---

9. Use the following command to ensure that everything worked the way it should with the data plane

```
linkerd -n emojivoto check --proxy
```

---

10. Retrieve the external IP of the emojivoto web service and browse it to see the application 

```
kubectl get svc web-svc -n emojivoto
```
```
https://<service-external-ip>:80
```

- Note: Clicking around, you might notice that some parts of emojivoto are broken! (intentionally) For example, if you click on a doughnut emoji, you'll get a 404 page

---

11. Since the demo app comes with a load generator, we can see live traffic metrics by running

```
linkerd -n emojivoto stat deploy
```

- Note: This will show the “golden” metrics for each deployment (Success rates, Request rates and Latency distribution percentiles)

---

12. Also we can use top to get a real-time view of which paths are being called

```
linkerd -n emojivoto top deploy --as $(gcloud config get-value account)
```

---

13. To go even deeper, we can use tap shows the stream of requests across a single pod, deployment, or even everything in the emojivoto namespace

```
linkerd -n emojivoto tap deploy/web --as $(gcloud config get-value account)
```

---

14. Retrieve the linkerd dashboard external IP and browse to the emojivoto namespace to see the application details 

```
kubectl get svc linkerd-web -n linkerd
```
```
https://<service-external-ip>:8084
```

- Note: All the above functionality is also available in the dashboard

- Note: You can see some pre-configured dashboards by clicking the Grafana icon in the overview page
