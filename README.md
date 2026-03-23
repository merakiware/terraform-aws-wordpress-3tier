# AWS 3-Tier WordPress Deployment
### Architectural Overview & Step-by-Step Guide

**Author:** Henry Barrera  
**GitHub:** [github.com/merakiware](https://github.com/merakiware)  
**Platform:** AWS | **Tools:** EC2, RDS, ALB, VPC, Bastion

---

## Scenario

I built this project because I fell in love with the terminal. The feeling of SSH-ing into a server and controlling everything through a command line — no mouse, no GUI, just you and the machine — was something I couldn't get enough of. This project was me pushing that further: spinning up a full 3-tier architecture on AWS and jumping through a Bastion host into a private server, setting up WordPress entirely from the terminal.

---

## Objectives

- Deploy a VPC with 3 public and 3 private subnets across 3 Availability Zones (AZ)
- Deploy an RDS instance and WordPress EC2 in a private subnet
- Deploy a Bastion EC2 server and Application Load Balancer (ALB) in the public subnet
- Configure Security Groups (SG) and networking to allow proper traffic flow between services
- Complete WordPress installation via the ALB DNS name in the browser

---

## Architecture

```
Internet
    │
    ▼
[ALB] ← public subnets (3 AZs)
    │
    ▼
[WordPress EC2] ← private subnet (no public IP)
    │
    ▼
[RDS MariaDB] ← private subnet (port 3306 only from WordPress-SG)

[Bastion Host] ← public subnet (SSH from your IP only → jump to WordPress EC2)
```

---

## Task 1 — VPC Setup

Navigate to VPC on the AWS Console and create a new VPC with the following configuration:

| Parameter | Value |
|-----------|-------|
| VPC CIDR Block | 10.0.0.0/16 |
| Public Subnets | 3 subnets across us-east-1a, us-east-1b, us-east-1c |
| Private Subnets | 3 subnets across us-east-1a, us-east-1b, us-east-1c |
| Internet Gateway | Attach to VPC for public subnet internet access |
| NAT Gateway | Deploy in 1 public subnet (single AZ for cost savings) |
| Route Tables | Public RT → IGW \| Private RT → NAT Gateway |

### Key Concepts

**NAT Gateway** — Enables instances in private subnets to send outbound traffic to the internet while preventing inbound connections. Must be placed in a public subnet. For high availability, deploy one NAT Gateway per AZ (higher cost).

**Internet Gateway (IGW)** — Allows communication between the VPC and the internet. Enables public subnet instances to reach the internet and be reachable from it.

---

## Task 2 — RDS MariaDB Setup

Navigate to RDS → Create Database with the following parameters:

| Parameter | Value |
|-----------|-------|
| Engine | MariaDB version 10.6.10 (compatible with free tier) |
| Instance Class | db.t2.micro (free tier eligible) |
| Username / Password | Choose a secure username and password |
| VPC | Select the custom VPC created above |
| Subnet Group | Private subnets only — RDS must not be publicly accessible |
| Public Access | No |
| Delete Protection | Optional — protects from accidental deletion at no extra cost |

---

## Task 3 — WordPress EC2 and Bastion Setup

### WordPress EC2 Configuration

| Parameter | Value |
|-----------|-------|
| AMI | Amazon Linux 2023 (AL2023) |
| Instance Type | t2.micro |
| Key Pair | Create new — store the .pem file securely on your local machine |
| VPC | Custom VPC created above |
| Subnet | Any private subnet — no public IP assigned |
| Auto-assign Public IP | Disabled |

> **Key Pair Note:** A key pair consists of a public key (stored by AWS on the instance) and a private key (stored as a .pem file locally). Required to SSH into the instance. Keep the private key secure and never share it.

### Bastion EC2 Configuration

Same configuration as WordPress EC2 with two differences:
- Located in a **public subnet**
- **Auto-assign Public IP: Enabled**

> The Bastion Security Group should allow SSH (port 22) inbound from **My IP only** — never open SSH to 0.0.0.0/0 in production.

---

## Task 4 — Security Group Configuration

> Best practice: always grant the minimum required permissions (principle of least privilege).

| Security Group | Inbound Rules |
|----------------|---------------|
| ALB-SG | HTTP (80) from 0.0.0.0/0 |
| Bastion-SG | SSH (22) from YOUR IP only |
| WordPress-SG | SSH (22) from Bastion-SG \| HTTP (80) from ALB-SG |
| RDS-SG | MySQL/MariaDB (3306) from WordPress-SG only |

This creates a security chain: **Internet → ALB → WordPress EC2 → RDS**. The RDS instance is never directly reachable from the internet.

---

## Task 5 — SSH to Bastion and WordPress Server

### Step 1 — SSH from local machine to Bastion

Set correct permissions on your key:
```bash
chmod 400 "WordPress-key-pair.pem"
```

Connect to the Bastion:
```bash
ssh -i "WordPress-key-pair.pem" ec2-user@<BASTION-PUBLIC-IP>
```

### Step 2 — Copy the PEM key to the Bastion host

From your local terminal, run `cat WordPress-key-pair.pem` and copy the full output. On the Bastion host:
```bash
nano WordPress-key-pair.pem
# Paste the key content, then press Ctrl+X to save and exit
```

### Step 3 — SSH from Bastion to WordPress EC2

Get the SSH command from the WordPress EC2 console (Connect → SSH client tab), then run it on the Bastion:
```bash
ssh -i "WordPress-key-pair.pem" ec2-user@<WORDPRESS-PRIVATE-IP>
```

---

## Task 6 — Install LAMP Stack on WordPress EC2

**LAMP** = Linux, Apache, MySQL/MariaDB, PHP. Run the following commands on the WordPress EC2.

```bash
# 1. Update the system
sudo dnf update -y

# 2. Install Apache and PHP
sudo dnf install -y httpd wget php-fpm php-mysqli php-json php php-devel

# 3. Install MariaDB client
sudo dnf install mariadb105-server

# 4. Start and enable Apache
sudo systemctl start httpd
sudo systemctl enable httpd

# 5. Verify Apache is running
sudo systemctl is-enabled httpd

# 6. Add ec2-user to apache group
sudo usermod -a -G apache ec2-user

# 7. Log out and reconnect, then verify group membership
exit
# SSH back in, then:
groups

# 8. Set ownership and permissions
sudo chown -R ec2-user:apache /var/www
sudo chmod 2775 /var/www && find /var/www -type d -exec sudo chmod 2775 {} \;
find /var/www -type f -exec sudo chmod 0664 {} \;

# 9. Create and delete test PHP file
echo "<?php phpinfo(); ?>" > /var/www/html/phpinfo.php
sudo dnf list installed httpd mariadb-server php-mysqlnd
rm /var/www/html/phpinfo.php
```

---

## Task 7 — Install WordPress

```bash
# 16. Install required packages
dnf install wget php-mysqlnd httpd php-fpm php-mysqli mariadb105-server php-json php php-devel -y

# 17. Download WordPress
wget https://wordpress.org/latest.tar.gz

# 18. Extract
tar -xzf latest.tar.gz

# 19. Start services
sudo systemctl start mariadb httpd

# 20. Connect to RDS
mysql -h <RDS-ENDPOINT> -u admin -p
# Enter the password set during RDS setup
```

### 21–27. Configure the WordPress Database

Inside the MariaDB prompt:
```sql
CREATE USER 'wordpress-user'@'%' IDENTIFIED BY 'your_strong_password';
CREATE DATABASE `wordpress-db`;
GRANT ALL PRIVILEGES ON `wordpress-db`.* TO 'wordpress-user'@'%';
FLUSH PRIVILEGES;
show databases;
exit
```

> The `%` in CREATE USER allows the user to connect from any host — required since WordPress EC2 and RDS are separate machines.

### 28–31. Configure wp-config.php

```bash
cp wordpress/wp-config-sample.php wordpress/wp-config.php
nano wordpress/wp-config.php
```

Update these values inside nano:

```php
define( 'DB_NAME', 'wordpress-db' );
define( 'DB_USER', 'wordpress-user' );
define( 'DB_PASSWORD', 'your_strong_password' );
define( 'DB_HOST', '<RDS-ENDPOINT>' );
```

> For Authentication Keys and Salts, generate random values at https://api.wordpress.org/secret-key/1.1/salt/ and replace the placeholder values.

---

## Task 8 — Final WordPress File Setup

```bash
# 32. Enable .htaccess in Apache config
sudo vim /etc/httpd/conf/httpd.conf
# Find <Directory "/var/www/html"> section
# Change: AllowOverride None  →  AllowOverride All

# 33. Install PHP graphics library
sudo dnf install php-gd

# 34–37. Fix file permissions
sudo chgrp -R apache /var/www
sudo chown -R apache /var/www
sudo chmod 2775 /var/www
find /var/www -type d -exec sudo chmod 2775 {} \;
find /var/www -type f -exec sudo chmod 0644 {} \;

# 38. Copy WordPress files to web root
cp -r wordpress/* /var/www/html/

# 39. Restart Apache
sudo systemctl restart httpd
```

---

## Task 9 — ALB Configuration

1. Create an Application Load Balancer mapped to all 3 public subnets
2. Assign ALB-SG to the ALB (allows HTTP port 80 from anywhere)
3. Create a Target Group (protocol: HTTP, port: 80)
4. Register the WordPress EC2 as a target in the Target Group
5. Edit Target Group Health Checks: change success code to include **302** (WordPress redirects on first load)
6. Create a Listener on port 80 forwarding to the Target Group
7. Update WordPress-SG inbound rules to allow HTTP from ALB-SG
8. Confirm Target Group shows **healthy** status for the WordPress EC2

---

## Conclusion

Copy the ALB DNS name into a browser to reach the WordPress installation page. Complete the WordPress setup wizard — choose a site title, admin username, and password. Your WordPress blog is now live and running on AWS.

### What Was Accomplished

- ✅ Deployed a custom VPC with 3 public and 3 private subnets across 3 AZs
- ✅ Launched a managed RDS MariaDB instance in a private subnet
- ✅ Deployed a WordPress EC2 server in a private subnet with no public IP
- ✅ Configured a Bastion host as the only SSH entry point into the private network
- ✅ Set up an Application Load Balancer routing public traffic to WordPress
- ✅ Installed a full LAMP stack and configured WordPress from the command line
- ✅ Applied least-privilege Security Group chaining throughout the architecture

### Possible Improvements

- Add HTTPS with AWS Certificate Manager (ACM) and an ALB HTTPS listener
- Deploy NAT Gateways in all 3 AZs for high availability
- Use AWS Secrets Manager to manage RDS credentials instead of wp-config.php
- Add CloudFront CDN in front of the ALB for global performance
- Enable RDS automated backups and Multi-AZ for production workloads

---

*Project by Henry Barrera | [github.com/merakiware](https://github.com/merakiware)*
