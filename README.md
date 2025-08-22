🔹 Introduction
In modern cloud computing, automation plays a key role in deploying scalable and reliable applications. This project demonstrates how to use Terraform (Infrastructure as Code) and Ansible (Configuration Management) to build and manage a 3-Tier Web Application Architecture on Amazon Web Services (AWS).

🔹 Problem Statement
Manually creating cloud resources and installing software is error-prone, time-consuming, and not scalable.
Developers need repeatable, version-controlled infrastructure.
Ops teams need automated configuration to ensure consistency.
Businesses require scalability and security while minimizing costs.

🔹 Objective
Use Terraform to provision infrastructure on AWS (VPC, subnets, EC2 instances, security groups).
Use Ansible to configure servers automatically (web, app, and database tiers).
Deploy a scalable and modular architecture that can be reused and extended.

🔹 Architecture
This project implements a 3-Tier Architecture:
Web Tier
Runs Nginx as a web server.
Accepts incoming HTTP requests from the internet.
Forwards requests to the Application Tier.
Application Tier
Hosts the application code (Python, Node.js, or Java).
Processes business logic.
Communicates with the Database Tier.
Database Tier
Runs MySQL as the backend database.
Stores persistent application data.
Accessible only from the Application Tier for security.

🔹 Tools & Technologies
AWS: Cloud provider for infrastructure.
Terraform: Infrastructure as Code to create VPC, EC2, Security Groups.
Ansible: Configuration Management to install software and configure servers.
SSH: Secure connection between Ansible and EC2 instances.
Linux (Ubuntu): Operating system on EC2 instances.

🔹 Workflow
Terraform Phase (Infrastructure as Code)
Define AWS resources in .tf files.
Run terraform apply to create:
VPC + subnets (public & private)
Security groups (allow HTTP/SSH/MySQL)
EC2 instances for Web, App, DB
Output IP addresses for Ansible.
Ansible Phase (Configuration Management)
Use Terraform output to create hosts.ini inventory.
Run ansible-playbook to:
Install and configure Nginx on Web server.
Install runtime (Python/Java/Node.js) on App server.
Install MySQL on DB server.
Validation
Access the web server’s public IP to confirm Nginx is running.
Verify App and DB setup using SSH.

🔹 Benefits of This Approach
Automation → No manual setup, repeatable deployments.
Scalability → Easily scale web/app tiers.
Consistency → Same config across environments (dev, staging, prod).
Security → Controlled network traffic between tiers.
Cost Efficiency → Uses AWS free-tier where possible.

🔹 Use Cases
Deploying multi-tier applications in AWS.
Building DevOps pipelines with IaC + CM.
Learning Terraform + Ansible integration.
Creating reusable modules for production-ready infrastructure.

🔹 Conclusion
This project showcases the power of combining Terraform (for provisioning) and Ansible (for configuration) to implement a 3-Tier architecture in AWS. The result is an automated, reliable, and secure environment that can be extended to host real-world applications.

<img width="717" height="442" alt="Screenshot 2025-08-22 180336" src="https://github.com/user-attachments/assets/7f1b9815-63a2-44b5-a3aa-9ba35142ea7c" />








