# 🚀 Ansible-Driven Configuration Management Inside Kubernetes Pods

## 📘 Overview
This project demonstrates manual setup of Ansible inside Kubernetes pods to configure and manage application containers that are running within the same cluster. It reflects a hybrid model of container-based configuration management and promotes Infrastructure-as-Code (IaC) principles inside Kubernetes.

Instead of relying on an external Ansible controller, this approach packages Ansible within a pod, which acts as the configuration manager. It connects to other pods (targets) via SSH to automate tasks like software installation or configuration updates.

## 📌 Objectives
- Deploy Ansible manually inside a Kubernetes pod
- Build a custom Docker image with Ansible pre-installed
- Create and manage target pods to be configured using Ansible
- Use SSH for communication between Ansible and target pods
- Demonstrate configuration tasks using playbooks

## ⚙️ Architecture
```
+---------------------+         +----------------------+
|  ansible-pod        |  SSH →  |   app-pod (nginx+ssh)|
|  (Ansible inside)   |         |  Target Application  |
+---------------------+         +----------------------+
         |
         |  (Runs Playbooks, uses Inventory)
         ↓
 Performs remote configurations
```

## 📁 Project Structure
```
project/
├── Dockerfile.ansible        # Custom Dockerfile for Ansible container
├── ansible-pod.yaml          # Pod spec for Ansible controller
├── app-pod.yaml              # Target pod to be configured via SSH
├── install-tools.yml         # Sample playbook to install packages
└── inventory                 # Ansible inventory file
```

## 🧰 Prerequisites
- Kubernetes cluster (Minikube, EKS, kubeadm, etc.)
- kubectl CLI configured
- Docker and Docker Hub account
- Basic understanding of YAML, Docker, Ansible, and Kubernetes
- SSH knowledge

## 🧑‍🍳 Step-by-Step Guide

### ✅ Step 1: Create Dockerfile for Ansible
Create a `Dockerfile.ansible` to build a base image with Ansible:

```dockerfile
# Dockerfile.ansible
FROM python:3.9-slim

RUN apt-get update && \
    apt-get install -y sshpass iputils-ping curl && \
    pip install ansible && \
    mkdir /ansible

WORKDIR /ansible

CMD [ "tail", "-f", "/dev/null" ]
```

### ✅ Step 2: Build and Push Docker Image
```bash
docker build -t himanshu8090/ansible-pod:v1 -f Dockerfile.ansible .
docker push himanshu8090/ansible-pod:v1
```

### ✅ Step 3: Create Ansible Pod in Kubernetes
Create a Kubernetes manifest `ansible-pod.yaml`:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: ansible-pod
spec:
  containers:
  - name: ansible
    image: himanshu8090/ansible-pod:v1
    tty: true
```

Apply it:
```bash
kubectl apply -f ansible-pod.yaml
```

### ✅ Step 4: Create Target Pod (with SSH)
To manage a pod via Ansible, the target pod must have an SSH server installed. You must create a custom image of NGINX or Ubuntu with OpenSSH.

Sample Dockerfile for Target Pod (`Dockerfile.ssh-nginx`):
```dockerfile
FROM ubuntu:20.04

RUN apt-get update && \
    apt-get install -y openssh-server nginx && \
    echo "root:root123" | chpasswd && \
    mkdir /var/run/sshd

EXPOSE 22 80

CMD ["/usr/sbin/sshd", "-D"]
```

Then:
```bash
docker build -t himanshu8090/nginx-ssh:v1 -f Dockerfile.ssh-nginx .
docker push himanshu8090/nginx-ssh:v1
```

### ✅ Step 5: Deploy Target Pod
Create `app-pod.yaml`:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: app-pod
  labels:
    app: nginx
spec:
  containers:
  - name: nginx-ssh
    image: himanshu8090/nginx-ssh:v1
    ports:
    - containerPort: 22
    - containerPort: 80
```

Deploy it:
```bash
kubectl apply -f app-pod.yaml
```

### ✅ Step 6: Access Ansible Pod
```bash
kubectl exec -it ansible-pod -- bash
```

Inside the container:

### ✅ Step 7: Create Ansible Inventory File
```bash
cat > inventory <<EOF
[web]
app-pod ansible_host=app-pod ansible_user=root ansible_password=root123 ansible_ssh_common_args='-o StrictHostKeyChecking=no'
EOF
```

### ✅ Step 8: Create a Playbook
Create `install-tools.yml`:

```yaml
- name: Install curl on web server
  hosts: web
  become: yes
  tasks:
    - name: Install curl
      apt:
        name: curl
        state: present
        update_cache: yes
```

### ✅ Step 9: Run the Playbook
```bash
ansible-playbook -i inventory install-tools.yml
```

You should see success messages indicating tasks were run on app-pod.

### ✅ Step 10: Verify the Changes
From your host or inside Ansible pod:
```bash
kubectl exec -it app-pod -- curl --version
```

## 📦 Enhancements (Optional)
- Use a Service and Headless DNS to manage connectivity to multiple pods
- Use ConfigMaps to mount playbooks and inventories
- Implement RBAC policies for pod-level access
- Extend to multi-node clusters with NodeSelector and Taints/Tolerations

## � Use Cases
- In-cluster Configuration Management
- Dev/Test environments for Ansible users
- Demo CI/CD workflows using GitOps + Ansible
- Automating legacy app configurations within Kubernetes

## 🙌 Author
**Himanshu Kumar Singh**  
DevOps & Cloud Enthusiast | B.Tech CSE  
📫 [LinkedIn](#)  
🐳 Docker Hub: [himanshu8090](#)

## 📄 License
This project is licensed under the MIT License.
```
