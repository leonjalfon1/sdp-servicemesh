# LAB 06: Working with Service Profiles

## Description

In this lab we will see how to work with Service Profiles to manage traffic

## Instructions

### Part 1: Configure the Service Profiles

1. Let's create a service profile for the webapp by using the Swagger spec

```
curl -sL https://raw.githubusercontent.com/leonjalfon1/sdp-servicemesh/main/resources/booksapp-webapp.swagger \
  | linkerd -n booksapp profile --open-api - webapp \
  | kubectl -n booksapp apply -f -
```

- Note: This command will do three things:
    1. Fetch the swagger specification for webapp.
    2. Take the spec and convert it into a service profile by using the profile command.
    3. Apply this configuration to the cluster.

- Note: to see the swagger spec run

```
curl https://raw.githubusercontent.com/leonjalfon1/sdp-servicemesh/main/resources/booksapp-webapp.swagger
```

---

2. Check out the profile that was generated

```
kubectl -n booksapp get serviceprofile -o yaml
```

--- 

3. To get profiles for authors and books as well, you can run:

```
curl -sL https://raw.githubusercontent.com/leonjalfon1/sdp-servicemesh/main/resources/booksapp-authors.swagger \
  | linkerd -n booksapp profile --open-api - authors \
  | kubectl -n booksapp apply -f -
```
```
curl -sL https://raw.githubusercontent.com/leonjalfon1/sdp-servicemesh/main/resources/booksapp-books.swagger \
  | linkerd -n booksapp profile --open-api - books \
  | kubectl -n booksapp apply -f -
```

- Note: to see the swagger specs run

```
curl https://raw.githubusercontent.com/leonjalfon1/sdp-servicemesh/main/resources/booksapp-authors.swagger
```

```
curl https://raw.githubusercontent.com/leonjalfon1/sdp-servicemesh/main/resources/booksapp-books.swagger
```

---

4. Let's use the tap command to ensure that all works

```
linkerd -n booksapp tap deploy/webapp -o wide --as $(gcloud config get-value account) | grep req
```

- Note: 
  1. **:authority** is the correct host
  2. **:path** correctly matches
  3. **rt_route** contains the name of the route

---

5. Use the routes command to see the metrics that have accumulated so far

```
linkerd -n booksapp routes svc/webapp
```

- Note: This will output a table of all the routes observed and their golden metrics
- Note: The [DEFAULT] route is a catch all for anything that does not match the service profile

---

6. Let's observe the outgoing requests as well (in the last step we saw the incoming requests)

```
linkerd -n booksapp routes deploy/webapp --to svc/books
```

- Note: This will show all requests and routes that originate in the webapp deployment and are destined to the books service.

---

### Part 2: Adding Retries

1. As it can take a while to update code and roll out a new version, let's tell Linkerd that it can retry requests to the failing endpoint.

- Note: This will increase request latencies, as requests will be retried multiple times, but not require changes in the code.

---

2. In this application, the success rate of requests from the books deployment to the authors service is poor. To see these metrics, run

```
linkerd -n booksapp routes deploy/books --to svc/authors
```

- Note: One thing that’s clear is that all requests from books to authors are to the HEAD /authors/{id}.json route and those requests are failing about 50% of the time.

---

3. To correct this, let’s edit the authors service profile and make those requests retryable by running

```
kubectl -n booksapp edit sp/authors.booksapp.svc.cluster.local
```
```
# You'll want to add isRetryable to the specific route.

spec:
  routes:
  - condition:
      method: HEAD
      pathRegex: /authors/[^/]*\.json
    name: HEAD /authors/{id}.json
    isRetryable: true ### ADD THIS LINE ###
```

---

4. After editing the service profile, Linkerd will begin to retry requests to this route automatically. We see a nearly immediate improvement in success rate by running

```
linkerd -n booksapp routes deploy/books --to svc/authors -o wide
```

- Note: The -o wide flag has added some columns to the routes view. These show the difference between EFFECTIVE_SUCCESS and ACTUAL_SUCCESS. The difference between these two show how well retries are working. EFFECTIVE_RPS and ACTUAL_RPS show how many requests are being sent to the destination service and and how many are being received by the client's Linkerd proxy.

- Note: With retries automatically happening now, success rate looks great but the p95 and p99 latencies have increased. This is to be expected because doing retries takes time.

---

### Part 3: Adding Timeouts

1. Let's take a look at the current latency for requests from webapp to the books service

```
linkerd -n booksapp routes deploy/webapp --to svc/books
```

- Note: Requests to the books service's PUT /books/{id}.json route include retries for when that service calls the authors service as part of serving those requests, as described in the previous section. This improves success rate, at the cost of additional latency.

---

2. For the purposes of this demo, let's set a 25ms timeout for calls to that route by edit the books service profile

```
kubectl -n booksapp edit sp/books.booksapp.svc.cluster.local
```
```
# Update the PUT /books/{id}.json route to have a timeout

spec:
  routes:
  - condition:
      method: PUT
      pathRegex: /books/[^/]*\.json
    name: PUT /books/{id}.json
    timeout: 25ms ### ADD THIS LINE ###
```

- Note: Linkerd will now return errors to the webapp REST client when the timeout is reached
- Note: The timeout includes retried requests and is the maximum amount of time a REST client would wait for a response.

---

3. Run routes to see what has changed (it may take a while)

```
linkerd -n booksapp routes deploy/webapp --to svc/books -o wide
```

- Note: The latency numbers include time spent in the webapp application itself, so it's expected that they exceed the 25ms timeout that we set for requests from webapp to books. 
-Note: We can see that the timeouts are working by observing that the effective success rate for our route has dropped below 100%.
