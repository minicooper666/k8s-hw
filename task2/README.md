# Task 2

### ConfigMap & Secrets

```cmd
D:\k8s\task2>kubectl create secret generic connection-string --from-literal=DATABASE_URL=postgres://connect --dry-run=client -o yaml > secret.yaml
D:\k8s\task2>kubectl create configmap user --from-literal=firstname=firstname --from-literal=lastname=lastname --dry-run=client -o yaml > cm.yaml
D:\k8s\task2>kubectl apply -f secret.yaml
secret/connection-string created

D:\k8s\task2>kubectl apply -f cm.yaml
configmap/user created

D:\k8s\task2>kubectl apply -f pod.yaml
pod/nginx created
```

## Check env in pod

```cmd
D:\k8s\task2>kubectl exec -it nginx -- bash
root@nginx:/# printenv
KUBERNETES_SERVICE_PORT_HTTPS=443
KUBERNETES_SERVICE_PORT=443
DATABASE_URL=postgres://connect
HOSTNAME=nginx
PWD=/
PKG_RELEASE=1~bullseye
HOME=/root
KUBERNETES_PORT_443_TCP=tcp://10.96.0.1:443
NJS_VERSION=0.7.2
TERM=xterm
SHLVL=1
KUBERNETES_PORT_443_TCP_PROTO=tcp
KUBERNETES_PORT_443_TCP_ADDR=10.96.0.1
lastname=lastname
KUBERNETES_SERVICE_HOST=10.96.0.1
KUBERNETES_PORT=tcp://10.96.0.1:443
KUBERNETES_PORT_443_TCP_PORT=443
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
firstname=firstname
NGINX_VERSION=1.21.6
_=/usr/bin/printenv
```

### Create deployment with simple application

```cmd
D:\k8s\task2>kubectl apply -f nginx-configmap.yaml
configmap/nginx-configmap created

D:\k8s\task2>kubectl apply -f deployment.yaml
deployment.apps/web created
```

### Get pod ip address

```cmd
NAME                   READY   STATUS    RESTARTS   AGE    IP            NODE       NOMINATED NODE   READINESS GATES
nginx                  1/1     Running   0          79m    172.17.0.7    minikube   <none>           <none>
web-6745ffd5c8-5lt7x   1/1     Running   0          102s   172.17.0.9    minikube   <none>           <none>
web-6745ffd5c8-tg6l8   1/1     Running   0          102s   172.17.0.10   minikube   <none>           <none>
web-6745ffd5c8-vp75b   1/1     Running   0          102s   172.17.0.8    minikube   <none>           <none>
```

- Try connect to pod with curl (curl pod_ip_address). What happens?
- From you PC

```cmd
D:\k8s\task2>curl 172.17.0.9
curl: (7) Failed to connect to 172.17.0.9 port 80: Timed out
```

- From minikube (minikube ssh)

```cmd
D:\k8s\task2>minikube.exe ssh
docker@minikube:~$ curl 172.17.0.9
web-6745ffd5c8-5lt7x
```

- From another pod (kubectl exec -it $(kubectl get pod |awk '{print $1}'|grep web-|head -n1) bash)

```cmd
D:\k8s\task2>kubectl exec -it web-6745ffd5c8-5lt7x bash
kubectl exec [POD] [COMMAND] is DEPRECATED and will be removed in a future version. Use kubectl exec [POD] -- [COMMAND] instead.
root@web-6745ffd5c8-5lt7x:/# curl 172.17.0.9
web-6745ffd5c8-5lt7x
root@web-6745ffd5c8-5lt7x:/# curl 172.17.0.10
web-6745ffd5c8-tg6l8
root@web-6745ffd5c8-5lt7x:/#
```

### Create service (ClusterIP)

The command that can be used to create a manifest template

```cmd
D:\k8s\task2>kubectl expose deployment/web --type=ClusterIP --dry-run=client -o yaml > service_template.yaml
```

Apply manifest

```cmd
D:\k8s\task2>kubectl apply -f service_template.yaml
service/web created
```

Get service CLUSTER-IP

```cmd
D:\k8s\task2>kubectl get svc
NAME         TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)   AGE
kubernetes   ClusterIP   10.96.0.1       <none>        443/TCP   8h
web          ClusterIP   10.110.42.142   <none>        80/TCP    28s
```

- Try connect to service (curl service_ip_address). What happens?

- From you PC

```cmd
D:\k8s\task2>curl 10.110.42.142
curl: (7) Failed to connect to 10.110.42.142 port 80: Timed out
```

- From minikube (minikube ssh) (run the command several times)

```cmd
D:\k8s\task2>minikube.exe ssh
Last login: Mon May  9 23:17:59 2022 from 192.168.49.1
docker@minikube:~$ curl 10.110.42.142
web-6745ffd5c8-vp75b
docker@minikube:~$ curl 10.110.42.142
web-6745ffd5c8-vp75b
docker@minikube:~$ curl 10.110.42.142
web-6745ffd5c8-tg6l8
```

- From another pod (kubectl exec -it $(kubectl get pod |awk '{print $1}'|grep web-|head -n1) bash) (run the command several times)

```cmd
D:\k8s\task2>kubectl exec -it web-6745ffd5c8-5lt7x bash
kubectl exec [POD] [COMMAND] is DEPRECATED and will be removed in a future version. Use kubectl exec [POD] -- [COMMAND] instead.
root@web-6745ffd5c8-5lt7x:/# curl 10.110.42.142
web-6745ffd5c8-vp75b
root@web-6745ffd5c8-5lt7x:/# curl 10.110.42.142
web-6745ffd5c8-tg6l8
```

### NodePort

```cmd
D:\k8s\task2>kubectl apply -f service-nodeport.yaml
service/web-np created
D:\k8s\task2>kubectl get service
NAME         TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)        AGE
kubernetes   ClusterIP   10.96.0.1        <none>        443/TCP        8h
web          ClusterIP   10.110.42.142    <none>        80/TCP         10m
web-np       NodePort    10.106.155.171   <none>        80:32554/TCP   19s
```

Note how port is specified for a NodePort service

### Checking the availability of the NodePort service type

```cmd
D:\k8s\task2>minikube ip
192.168.49.2

D:\k8s\task2>curl 192.168.49.2:32554
curl: (7) Failed to connect to 192.168.49.2 port 32554: Timed out
```

!Need to figure out, should work.

```zsh
➜  task_2 git:(main) ✗ curl 192.168.64.2:31857
web-6745ffd5c8-9752x
```

Works fine on macos.

### Headless service

```cmd
D:\k8s\task2>kubectl apply -f service-headless.yaml
service/web-headless created
```

### DNS

Connect to any pod

```cmd
D:\k8s\task2>kubectl exec -it web-6745ffd5c8-5lt7x bash
kubectl exec [POD] [COMMAND] is DEPRECATED and will be removed in a future version. Use kubectl exec [POD] -- [COMMAND] instead.
root@web-6745ffd5c8-5lt7x:/# cat /etc/resolv.conf
nameserver 10.96.0.10
search default.svc.cluster.local svc.cluster.local cluster.local
options ndots:5
```

Compare the IP address of the DNS server in the pod and the DNS service of the Kubernetes cluster.

- Compare headless and clusterip
  Inside the pod run nslookup to normal clusterip and headless. Compare the results.
  You will need to create pod with dnsutils.

```cmd
root@web-6745ffd5c8-5lt7x:/# nslookup 10.110.42.142
142.42.110.10.in-addr.arpa      name = web.default.svc.cluster.local.

root@web-6745ffd5c8-5lt7x:/# nslookup 10.106.155.171
171.155.106.10.in-addr.arpa     name = web-np.default.svc.cluster.local.

root@web-6745ffd5c8-5lt7x:/# nslookup web.efault.svc.cluster.local.
Server:         10.96.0.10
Address:        10.96.0.10#53

Name:   web.default.svc.cluster.local
Address: 10.110.42.142

root@web-6745ffd5c8-5lt7x:/# nslookup web-np.default.svc.cluster.local.
Server:         10.96.0.10
Address:        10.96.0.10#53

Name:   web-np.default.svc.cluster.local
Address: 10.106.155.171
```

### [Ingress](https://kubernetes.github.io/ingress-nginx/deploy/#minikube)

Enable Ingress controller

```cmd
D:\k8s\task2>minikube addons enable ingress
* After the addon is enabled, please run "minikube tunnel" and your ingress resources would be available at "127.0.0.1"
  - Используется образ k8s.gcr.io/ingress-nginx/controller:v1.1.1
  - Используется образ k8s.gcr.io/ingress-nginx/kube-webhook-certgen:v1.1.1
  - Используется образ k8s.gcr.io/ingress-nginx/kube-webhook-certgen:v1.1.1
* Verifying ingress addon...
* The 'ingress' addon is enabled
```

Let's see what the ingress controller creates for us

```cmd
D:\k8s\task2>kubectl get pods -n ingress-nginx
NAME                                       READY   STATUS      RESTARTS   AGE
ingress-nginx-admission-create-glscf       0/1     Completed   0          57s
ingress-nginx-admission-patch-9jztx        0/1     Completed   1          57s
ingress-nginx-controller-cc8496874-nslzj   1/1     Running     0          57s


D:\k8s\task2>kubectl get pod ingress-nginx-controller-cc8496874-nslzj -n ingress-nginx -o yaml
apiVersion: v1
kind: Pod
metadata:
  creationTimestamp: "2022-05-09T23:54:28Z"
  generateName: ingress-nginx-controller-cc8496874-
  labels:
    app.kubernetes.io/component: controller
    app.kubernetes.io/instance: ingress-nginx
    app.kubernetes.io/name: ingress-nginx
    gcp-auth-skip-secret: "true"
    pod-template-hash: cc8496874
  name: ingress-nginx-controller-cc8496874-nslzj
  namespace: ingress-nginx
  ownerReferences:
  - apiVersion: apps/v1
    blockOwnerDeletion: true
    controller: true
    kind: ReplicaSet
    name: ingress-nginx-controller-cc8496874
    uid: 0e88f0ef-99d1-41f7-bf39-973bee69b076
  resourceVersion: "23210"
  uid: c52994b2-f4cc-4dce-9cb1-e8cb01e9c333
spec:
  containers:
  - args:
    - /nginx-ingress-controller
    - --election-id=ingress-controller-leader
    - --controller-class=k8s.io/ingress-nginx
    - --watch-ingress-without-class=true
    - --configmap=$(POD_NAMESPACE)/ingress-nginx-controller
    - --tcp-services-configmap=$(POD_NAMESPACE)/tcp-services
    - --udp-services-configmap=$(POD_NAMESPACE)/udp-services
    - --validating-webhook=:8443
    - --validating-webhook-certificate=/usr/local/certificates/cert
    - --validating-webhook-key=/usr/local/certificates/key
    env:
    - name: POD_NAME
      valueFrom:
        fieldRef:
          apiVersion: v1
          fieldPath: metadata.name
    - name: POD_NAMESPACE
      valueFrom:
        fieldRef:
          apiVersion: v1
          fieldPath: metadata.namespace
    - name: LD_PRELOAD
      value: /usr/local/lib/libmimalloc.so
    image: k8s.gcr.io/ingress-nginx/controller:v1.1.1@sha256:0bc88eb15f9e7f84e8e56c14fa5735aaa488b840983f87bd79b1054190e660de
    imagePullPolicy: IfNotPresent
    lifecycle:
      preStop:
        exec:
          command:
          - /wait-shutdown
    livenessProbe:
      failureThreshold: 5
      httpGet:
        path: /healthz
        port: 10254
        scheme: HTTP
      initialDelaySeconds: 10
      periodSeconds: 10
      successThreshold: 1
      timeoutSeconds: 1
    name: controller
    ports:
    - containerPort: 80
      hostPort: 80
      name: http
      protocol: TCP
    - containerPort: 443
      hostPort: 443
      name: https
      protocol: TCP
    - containerPort: 8443
      name: webhook
      protocol: TCP
    readinessProbe:
      failureThreshold: 3
      httpGet:
        path: /healthz
        port: 10254
        scheme: HTTP
      initialDelaySeconds: 10
      periodSeconds: 10
      successThreshold: 1
      timeoutSeconds: 1
    resources:
      requests:
        cpu: 100m
        memory: 90Mi
    securityContext:
      allowPrivilegeEscalation: true
      capabilities:
        add:
        - NET_BIND_SERVICE
        drop:
        - ALL
      runAsUser: 101
    terminationMessagePath: /dev/termination-log
    terminationMessagePolicy: File
    volumeMounts:
    - mountPath: /usr/local/certificates/
      name: webhook-cert
      readOnly: true
    - mountPath: /var/run/secrets/kubernetes.io/serviceaccount
      name: kube-api-access-jts4d
      readOnly: true
  dnsPolicy: ClusterFirst
  enableServiceLinks: true
  nodeName: minikube
  nodeSelector:
    kubernetes.io/os: linux
    minikube.k8s.io/primary: "true"
  preemptionPolicy: PreemptLowerPriority
  priority: 0
  restartPolicy: Always
  schedulerName: default-scheduler
  securityContext: {}
  serviceAccount: ingress-nginx
  serviceAccountName: ingress-nginx
  terminationGracePeriodSeconds: 0
  tolerations:
  - effect: NoSchedule
    key: node-role.kubernetes.io/master
    operator: Equal
  - effect: NoExecute
    key: node.kubernetes.io/not-ready
    operator: Exists
    tolerationSeconds: 300
  - effect: NoExecute
    key: node.kubernetes.io/unreachable
    operator: Exists
    tolerationSeconds: 300
  volumes:
  - name: webhook-cert
    secret:
      defaultMode: 420
      secretName: ingress-nginx-admission
  - name: kube-api-access-jts4d
    projected:
      defaultMode: 420
      sources:
      - serviceAccountToken:
          expirationSeconds: 3607
          path: token
      - configMap:
          items:
          - key: ca.crt
            path: ca.crt
          name: kube-root-ca.crt
      - downwardAPI:
          items:
          - fieldRef:
              apiVersion: v1
              fieldPath: metadata.namespace
            path: namespace
status:
  conditions:
  - lastProbeTime: null
    lastTransitionTime: "2022-05-09T23:54:28Z"
    status: "True"
    type: Initialized
  - lastProbeTime: null
    lastTransitionTime: "2022-05-09T23:55:08Z"
    status: "True"
    type: Ready
  - lastProbeTime: null
    lastTransitionTime: "2022-05-09T23:55:08Z"
    status: "True"
    type: ContainersReady
  - lastProbeTime: null
    lastTransitionTime: "2022-05-09T23:54:28Z"
    status: "True"
    type: PodScheduled
  containerStatuses:
  - containerID: docker://9ae74dce3750facf49f3f987e74d33bbc0d1506879eae93c65d8a814d5b5db86
    image: k8s.gcr.io/ingress-nginx/controller@sha256:0bc88eb15f9e7f84e8e56c14fa5735aaa488b840983f87bd79b1054190e660de
    imageID: docker-pullable://k8s.gcr.io/ingress-nginx/controller@sha256:0bc88eb15f9e7f84e8e56c14fa5735aaa488b840983f87bd79b1054190e660de
    lastState: {}
    name: controller
    ready: true
    restartCount: 0
    started: true
    state:
      running:
        startedAt: "2022-05-09T23:54:54Z"
  hostIP: 192.168.49.2
  phase: Running
  podIP: 172.17.0.11
  podIPs:
  - ip: 172.17.0.11
  qosClass: Burstable
  startTime: "2022-05-09T23:54:28Z"
```

Create Ingress

```cmd
D:\k8s\task2>kubectl apply -f ingress.yaml
ingress.networking.k8s.io/ingress-web created

D:\k8s\task2>curl 192.168.49.2
curl: (7) Failed to connect to 192.168.49.2 port 80: Timed out
```

!Another problem with windows config.

```zsh
➜  task_2 git:(main) ✗ curl $(minikube ip)
web-6745ffd5c8-dtbr6
```

Again, works fine on macos with the same steps.

### Homework

- In Minikube in namespace kube-system, there are many different pods running. Your task is to figure out who creates them, and who makes sure they are running (restores them after deletion).

```cmd
D:\k8s\task2>kubectl get pods -n kube-system
NAME                               READY   STATUS    RESTARTS        AGE
coredns-64897985d-rswrt            1/1     Running   0               5h28m
etcd-minikube                      1/1     Running   0               5h29m
kube-apiserver-minikube            1/1     Running   0               5h29m
kube-controller-manager-minikube   1/1     Running   0               5h29m
kube-proxy-bqppj                   1/1     Running   0               5h28m
kube-scheduler-minikube            1/1     Running   0               5h29m
storage-provisioner                1/1     Running   2 (5h28m ago)   5h28m
```

Let's test what happens when we kill some core k8s components:

```cmd
D:\k8s\task2>kubectl delete pod etcd-minikube --namespace kube-system
pod "etcd-minikube" deleted

D:\k8s\task2>kubectl get pods -n kube-system
NAME                               READY   STATUS    RESTARTS        AGE
coredns-64897985d-rswrt            1/1     Running   0               5h35m
etcd-minikube                      0/1     Pending   0               3s
kube-apiserver-minikube            1/1     Running   0               5h35m
kube-controller-manager-minikube   1/1     Running   0               5h35m
kube-proxy-bqppj                   1/1     Running   0               5h35m
kube-scheduler-minikube            1/1     Running   0               5h35m
storage-provisioner                1/1     Running   2 (5h35m ago)   5h35m

D:\k8s\task2>kubectl get pods -n kube-system
NAME                               READY   STATUS    RESTARTS        AGE
coredns-64897985d-rswrt            1/1     Running   0               5h35m
etcd-minikube                      1/1     Running   0               25s
kube-apiserver-minikube            1/1     Running   0               5h36m
kube-controller-manager-minikube   1/1     Running   0               5h36m
kube-proxy-bqppj                   1/1     Running   0               5h35m
kube-scheduler-minikube            1/1     Running   0               5h36m
storage-provisioner                1/1     Running   2 (5h35m ago)   5h36m
```

ETCD autorestarts almost immediately as it is required to store the cluster state and some auth info.

```cmd
D:\k8s\task2>kubectl delete pod kube-apiserver-minikube --namespace kube-system
pod "kube-apiserver-minikube" deleted

D:\k8s\task2>kubectl get pods -n kube-system
NAME                               READY   STATUS    RESTARTS        AGE
coredns-64897985d-rswrt            1/1     Running   0               5h42m
etcd-minikube                      1/1     Running   0               6m27s
kube-apiserver-minikube            1/1     Running   0               2s
kube-controller-manager-minikube   1/1     Running   0               5h42m
kube-proxy-bqppj                   1/1     Running   0               5h42m
kube-scheduler-minikube            1/1     Running   0               5h42m
storage-provisioner                1/1     Running   2 (5h41m ago)   5h42m
```

API server restart immediately as it is the central module of k8s control plane. Nothing using 'kubectl' command will work if API is unavailable.

Everything marked with '-minicube' suffix is a core module being started by kubelet module running on every control plane node.

In this example there is one pod of daemonset type (kube-proxy-bqppj).
Also there is one pod of deployment type (coredns-64897985d-rswrt).

Core components controller-manager and scheduler in deep connection with ETCD and kubectl ensure that pods are in healthy state and perform any maintenance tasks such as restart or recreate.

- Implement Canary deployment of an application via Ingress. Traffic to canary deployment should be redirected if you add "canary:always" in the header, otherwise it should go to regular deployment.
  Set to redirect a percentage of traffic to canary deployment.

## Will foolow VK Cloud Solutions guide

This task was made on macos with zsh completely.

1. Creating prod namespace

```zsh
➜  task_2 git:(main) ✗ kubectl create ns hw-production
namespace/hw-production created
```

2. Deploying standard example from k8s KB

```zsh
➜  task_2 git:(main) ✗ kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/docs/examples/http-svc.yaml -n hw-production
deployment.apps/http-svc created
service/http-svc created
```

3. Using hw-ingress.yaml file making ingress for our service from previous step
   We need a slight modification to VKCS file to get our ingress working on minikube.

```zsh
➜  task_2 git:(main) ✗ kubectl apply -f hw-ingress.yaml -n hw-production
ingress.networking.k8s.io/http-svc created
```

4. Creating canary-release namespace

```zsh
➜  task_2 git:(main) ✗ kubectl create ns hw-canary
namespace/hw-canary created
```

5. Deploying the same example as in step 2 but in canary namespace

```zsh
➜  task_2 git:(main) ✗ kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/docs/examples/http-svc.yaml -n hw-canary
deployment.apps/http-svc created
service/http-svc created
```

6. Using hw-ingress-canary.yaml making an ingress for canary version.
   We still need to make some editions to the VKCS example.

```zsh
➜  task_2 git:(main) ✗ kubectl apply -f hw-ingress-canary.yaml -n hw-canary
ingress.networking.k8s.io/http-svc created
```

7. Checking that both ingresses have the same IP:

```zsh
➜  task_2 git:(main) ✗ kubectl get ingress -n hw-production
NAME       CLASS    HOSTS           ADDRESS        PORTS   AGE
http-svc   <none>   homework.epam   192.168.64.2   80      24m
➜  task_2 git:(main) ✗ kubectl get ingress -n hw-canary
NAME       CLASS    HOSTS           ADDRESS        PORTS   AGE
http-svc   <none>   homework.epam   192.168.64.2   80      4m14s
```

8. Using provided ruby script (we also can do this with simple bash, but why not to use the prepaired example) we check our ingress canary policy:

```zsh
➜  task_2 git:(main) ✗ ruby test.rb
{"hw-production"=>912, "hw-canary"=>88}
```

That result tells us that 8.8% of requests were sent to canary version, it is about 10% and is not really accurate.
