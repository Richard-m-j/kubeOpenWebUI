# Definitive Guide: Deploying the Web Application on a New EKS Cluster

This guide provides the complete, end-to-end instructions to deploy the application from scratch on a new EC2 instance and a new EKS cluster. It incorporates all the fixes and final configurations discovered during our debugging session.

---

## Phase 1: ⚙️ New EC2 Instance & Tool Setup

This phase prepares your new EC2 instance to be your control node.

### Step 1: Launch and Configure the New EC2 Instance
1. Launch a new EC2 instance. An **Ubuntu 22.04** or newer image is recommended (a `t3.medium` or larger is a good size).
2. **Crucial:** When launching, you must create and attach an **IAM Role** to the instance. In the "IAM instance profile" section, create a new role and attach the **`AdministratorAccess`** AWS managed policy to it. This is the permanent solution to the local account ID and permissions issues we faced.
3. Connect to your new EC2 instance via SSH.

### Step 2: Install All Required Tools
Run these commands to install the necessary command-line tools.

1. **kubectl:**
   ```bash
   curl -O "https://s3.us-west-2.amazonaws.com/amazon-eks/1.29.3/2024-04-19/bin/linux/amd64/kubectl"
   chmod +x ./kubectl
   sudo mv ./kubectl /usr/local/bin
   ```

2. **eksctl:**
   ```bash
   curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
   sudo mv /tmp/eksctl /usr/local/bin
   ```

3. **Helm:**
   ```bash
   curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
   ```

### Step 3: Get Your Application Code
Transfer your `kubeOpenWebUI` project folder to the new EC2 instance using `scp`, or clone it from your Git repository.

```bash
# Example: git clone <your-repo-url>
# Navigate into the correct directory
cd kubeOpenWebUI/kubernetes/
```

---

## Phase 2: 📝 Finalizing Your Kubernetes Manifests

Before deploying, we must apply all the fixes we discovered to your YAML files.

### Step 1: Create `ingress-class.yaml`

Ensure this file exists in your `/kubernetes` directory with the correct `apiVersion`.

```yaml
# ingress-class.yaml
apiVersion: networking.k8s.io/v1
kind: IngressClass
metadata:
  name: alb
spec:
  controller: ingress.k8s.aws/alb
```

### Step 2: Correct `kustomization.yaml`

Edit this file to include `ingress-class.yaml`. This was a key fix.

```yaml
# kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
namespace: open-webui
resources:
  - namespace.yaml
  - ebs-storageclass.yaml
  - ingress-class.yaml  # <-- Make sure this line is added
  - pvc.yaml
  - statefulset.yaml
  - webui-deployment.yaml
  - services.yaml
  - ingress.yaml
```

### Step 3: Correct `services.yaml`

Edit this file to change the `open-webui-service` type from `NodePort` to `ClusterIP`. This was the fix for the empty Target Group issue.

```yaml
# services.yaml (only showing the changed part for open-webui-service)
---
apiVersion: v1
kind: Service
metadata:
  name: open-webui-service
spec:
  type: ClusterIP # <-- Ensure this is ClusterIP, not NodePort
  selector:
    app: open-webui
  ports:
    - protocol: TCP
      port: 8080
      targetPort: 8080
```

### Step 4: Correct `ingress.yaml`

Edit this file to use `ingressClassName`.

```yaml
# ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: open-webui-ingress
  annotations:
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/target-type: ip
spec:
  ingressClassName: alb # <-- Ensure this line exists and is correct
  rules:
    - http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: open-webui-service
                port:
                  number: 8080
```

---

## Phase 3: 🏗️ Building the EKS Infrastructure

Now, you will create the EKS cluster and its essential add-ons.

### Step 1: Create the EKS Cluster

This will take 15-20 minutes.

```bash
eksctl create cluster \
--name openwebui-cluster \
--region ap-southeast-1 \
--version 1.29 \
--nodegroup-name standard-workers \
--node-type t3.large \
--nodes 2 \
--with-oidc
```

After it completes, `kubectl` will be automatically configured. Verify with `kubectl get nodes`.

### Step 2: Create the EBS CSI Driver Add-on

```bash
eksctl create addon \
--name aws-ebs-csi-driver \
--cluster openwebui-cluster \
--region ap-southeast-1
```

### Step 3: Install the AWS Load Balancer Controller

1. **Download the latest IAM policy document:**
   ```bash
   curl -O https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/main/docs/install/iam_policy.json
   ```

2. **Create the IAM policy:**
   ```bash
   aws iam create-policy \
       --policy-name AWSLoadBalancerControllerIAMPolicy \
       --policy-document file://iam_policy.json
   ```

3. **Create the Service Account and Role:**
   ```bash
   eksctl create iamserviceaccount \
     --cluster=openwebui-cluster \
     --namespace=kube-system \
     --name=aws-load-balancer-controller \
     --region=ap-southeast-1 \
     --attach-policy-arn=arn:aws:iam::$(aws sts get-caller-identity --query Account --output text):policy/AWSLoadBalancerControllerIAMPolicy \
     --approve
   ```

4. **Install the controller with Helm:**
   ```bash
   helm repo add eks https://aws.github.io/eks-charts
   helm repo update eks
   helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
     -n kube-system \
     --set clusterName=openwebui-cluster \
     --set serviceAccount.create=false \
     --set serviceAccount.name=aws-load-balancer-controller
   ```

---

## Phase 4: 🚀 Deploying and Accessing Your Application

This is the final phase.

### Step 1: Deploy Your Application

Navigate to your `/kubernetes` directory and run the single command that applies all your corrected manifests.

```bash
kubectl apply -k .
```

### Step 2: Verify the Deployment

1. **Check your pods:**
   ```bash
   kubectl get pods -n open-webui
   ```
   Wait for `ollama-0` and the `open-webui` pod to be `Running`.

2. **Check the Ingress:**
   ```bash
   kubectl get ingress -n open-webui -w
   ```
   Wait for the `ADDRESS` column to be populated with a DNS name.

### Step 3: Access Your Application

Once the address appears, get the URL and open it in your browser.

```bash
echo "http://$(kubectl get ingress open-webui-ingress -n open-webui -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')"
```

You have now successfully deployed the application from scratch.

```