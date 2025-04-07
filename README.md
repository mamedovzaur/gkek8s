# Creating GKE cluster with ingress, network policy, and autoscaling

# List of works.
-----
 
## 1. Kubernetes Cluster Setup
## 2. Build and Push Web Application 
## 3. Deploy Web Application into the kubernetes cluster
## 4. Adding Network policy for the security purposes 
## 5. Autoscaling Based on HTTP Request Rate
## 6. Incident Simulation
</br >
</br > 

# Common task: Installing necessary tools.

- [x] DOCKER installing:
```shell
curl -fsSL https://get.docker.com | sudo bash
```
- [x] GCLOUD installing:
```shell
echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list && curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg && sudo apt update -y && apt-get install google-cloud-sdk -y && \ 
sudo apt-get install -y google-cloud-cli-gke-gcloud-auth-plugin
```
- [x] TERRAFORM installing:
```shell
sudo apt-get install -y gnupg software-properties-common &&
wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg > /dev/null
gpg --no-default-keyring --keyring /usr/share/keyrings/hashicorp-archive-keyring.gpg --fingerprint &&
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list && sudo apt update -y && \
sudo apt-get install -y terraform
```
- [x] KUBECTL installing:
```shell
sudo apt-get install -y apt-transport-https ca-certificates curl gnupg && \
sudo mkdir -p -m 755 /etc/apt/keyrings && \
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.32/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg && \
sudo chmod 644 /etc/apt/keyrings/kubernetes-apt-keyring.gpg && \
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.32/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list && sudo chmod 644 /etc/apt/sources.list.d/kubernetes.list && \
sudo apt-get update -y && \
sudo apt-get install -y kubectl
```
- [x] HELM installing:
```shell
curl https://baltocdn.com/helm/signing.asc | gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg > /dev/null && \
sudo apt-get install apt-transport-https --yes && \
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list && \
sudo apt-get update -y && sudo apt-get install helm
```
# 1. Kubernetes Cluster Setup
- Login into GCP console using your login and password.
- Create new project. (we will use it while creating infrastructure).
- Create artifact registry for docker images.
- Deploy kubernetes cluster with terraform tool:
```shell
cd terraform
terraform init
terraform plan
gcloud auth application-default login #necessary for terraform
terraform apply
```
- Checking newly created cluster in GCP console.
![Alt](images/3.png)

- Login to created cluster with gcloud tool.
```shell

gcloud config set compute/region us-central1
gcloud config set compute/zone us-central1-f
gcloud container clusters get-credentials zaur-gke-cluster

```
- Checking cluster with kubectl tool.
```shell

kubectl config get-clusters

```
![Alt](images/4.png)
- You can check list of all available pods by command:
```shell

kubectl get po -A

```

# 2. Build and Deploy Web Application
We will use sample web application with three endpoints ( '/', '/health', and '/chaos' )
```python

@app.route('/', methods=['GET'])
def index():
    """Standard application response."""
    return jsonify({"message": "Hello from world!"})

@app.route('/chaos', methods=['GET'])
def chaos():
    """Endpoint to trigger a health-check failure scenario."""
    global IsChaosEnabled
    IsChaosEnabled = not IsChaosEnabled  # Toggle the chaos state

    if IsChaosEnabled:
        return jsonify({"message": "Chaos mode activated!"}), 500  # Simulate failure
    else:
        return jsonify({"message": "Chaos mode deactivated!"})

@app.route('/health', methods=['GET'])
def health():
    """Health check endpoint. Return 200 if healthy, 500 if chaotic."""
    if IsChaosEnabled:
        return jsonify({"status": "unhealthy"}), 500
    else:
        return jsonify({"status": "healthy"}), 200

```
Get whole code in the webapp folder.

- [X] Creating docker image from python code:
```shell
cd webapp
sudo docker build -t python-http-app .
sudo docker images # will show us docker images
```
![Alt](images/1.png)

- [X] Tagging and Pulling created docker image into google cloud registry:
```shell
docker tag 1b017fb0b721 us-central1-docker.pkg.dev/zaurproject/zaurrepo/python-http-app:00004
docker push us-central1-docker.pkg.dev/zaurproject/zaurrepo/python-http-app:00004
```
![Alt](images/2.png)


## 3. Deploying Web Application into the kubernetes cluster

- [X] Connecting to the cluster
```shell

gcloud config set compute/region us-central1
gcloud config set compute/zone us-central1-f
gcloud container clusters get-credentials zaur-gke-cluster

```
- [X] Creating new namespace for our application
```shell
kubectl create namespace webapp
```

- [X] Deploying webapp application to the kubernetes
```shell
cd k8s
kubectl apply -f webapp-deployment.yaml
```
- [X] Checking newly created deployment
```shell
kubectl describe deployment webapp -nwebapp
```
![Alt](images/7.png)
- [X] Checking for running pods
```shell
kubectl get po -nwebapp
```
![Alt](images/6.png)

- [X] Adding ingress controller and application service
```shell
kubectl apply -f webapp-service.yaml
kubectl apply -f ingress-controller.yaml
kubectl apply -f ingress.yaml
```
```shell
kubectl get svc -nwebapp
```
![Alt](images/8.png)
```shell
kubectl get ingress -nwebapp
```
![Alt](images/9.png)

- [X] Adding host name webapp.loc to our host file and check
```shell
curl http://webapp.loc
```
![Alt](images/11.png)
![Alt](images/10.png)

# 4. Adding Network policy for the security purposes 
- [X] Deny all traffic between pods in webapp namesapace
```shell
cd k8s
kubectl apply -f NetworkDenyAll.yaml
```

- [X] Allow only ingress traffic from ingress controller
```shell
cd k8s
kubectl apply -f NetworkAllowFromIngress.yaml
```

- [X] Testing networks
```shell
kubectl get po -nwebapp -o wide
```
```shell
NAME                     READY   STATUS    RESTARTS        AGE     IP           NODE                                                  NOMINATED NODE   READINESS GATES
webapp-dfbdc55d4-h8bzz   1/1     Running   0               4d17h   10.92.1.21   gke-zaur-gke-cluster-primary-node-poo-d1b4ea3c-f7pu   <none>           <none>
webapp-dfbdc55d4-p786d   1/1     Running   3 (4d18h ago)   5d      10.92.2.13   gke-zaur-gke-cluster-primary-node-poo-d1b4ea3c-xywy   <none>           <none>
```
Connecting to the first pod and ping the second pod:
```shell
kubectl exec -it -nwebapp webapp-dfbdc55d4-h8bzz -- /bin/bash
```
```shell
root@webapp-dfbdc55d4-h8bzz:/app# ping 10.92.2.13
PING 10.92.2.13 (10.92.2.13) 56(84) bytes of data.

--- 10.92.2.13 ping statistics ---
18 packets transmitted, 0 received, 100% packet loss, time 454ms

root@webapp-dfbdc55d4-h8bzz:/app#
```
Connecting to the second pod and ping the first pod:
```shell
kubectl exec -it -nwebapp webapp-dfbdc55d4-p786d -- /bin/bash
```
```shell
root@webapp-dfbdc55d4-p786d:/app# ping 10.92.1.21
PING 10.92.1.21 (10.92.1.21) 56(84) bytes of data.

--- 10.92.1.21 ping statistics ---
17 packets transmitted, 0 received, 100% packet loss, time 410ms

root@webapp-dfbdc55d4-p786d:/app#
```

# 5. Autoscaling Based on HTTP Request Rate
- [X] Deploying prometheus
```shell
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm install webapp-prom prometheus-community/prometheus --create-namespace -n monitoring
```
```shell
kubectl get po -nmonitoring
```
```shell
NAME                                                  READY   STATUS    RESTARTS   AGE
webapp-prom-alertmanager-0                            1/1     Running   0          5d2h
webapp-prom-kube-state-metrics-5f466455c5-wqhkb       1/1     Running   0          5d2h
webapp-prom-prometheus-node-exporter-8tvwh            1/1     Running   0          5d2h
webapp-prom-prometheus-node-exporter-8zcnh            1/1     Running   0          5d2h
webapp-prom-prometheus-pushgateway-5f5ff48f7c-9jv7c   1/1     Running   0          5d2h
webapp-prom-prometheus-server-84f456874b-wtsqj        2/2     Running   0          5d2h
```
- [X] Deploying KEDA
```shell
helm repo add kedacore https://kedacore.github.io/charts
helm repo update
helm install keda kedacore/keda --namespace keda --create-namespace
```
```shell
kubectl get po -nkeda
```
```shell
NAME                                               READY   STATUS    RESTARTS        AGE
keda-admission-webhooks-7589cd46c7-2ttsp           1/1     Running   0               4d18h
keda-operator-b479b44bd-68r5d                      1/1     Running   1 (4d18h ago)   4d18h
keda-operator-metrics-apiserver-5bfbf87b69-rcd6d   1/1     Running   0               4d18h
```
- [X] Deploying KEDA scaledobject
```shell
kubectl apply -f hpa.yaml
```
```shell
kubectl get scaledobject -nwebapp
```
```shell
NAME               SCALETARGETKIND      SCALETARGETNAME   MIN   MAX   READY   ACTIVE   FALLBACK   PAUSED    TRIGGERS   AUTHENTICATIONS   AGE
ingress-requests   apps/v1.Deployment   webapp            2     15    True    False    False      Unknown                                4d18h
```