sudo apt-get update
sudo apt-get install -y docker.io
sudo adduser chris --disabled-password
sudo usermod -aG sudo chris
sudo usermod -aG docker chris
sudo echo "chris    ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
sudo -u chris ssh-keygen -b 2048 -t rsa -f /home/chris/.ssh/id_rsa -q -N ""
sudo -u chris touch /home/chris/.ssh/authorized_keys
sudo -u chris echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDGVigDawGVavWoRBeBfGBju9q5GVWHlgYK/5udQhLOci4WmjXomw8tmKdYWl2J1jit+274R/hAYL1ysayTNeaKsX9josJIdTAvQ6+3Bej/piYPc14VLbjSOc4ov99mjyveWk31UOKyW96JC0ioHZYk60DiEB9s66PjOLAlmLJWSrA1L/+s2gtbM9FmDjboKIpNTAyuAVRzejIWymIaJiU2O3RLdxZhc5PNxU4Lo6OMGf4ecLbwkHuyQy/o0WbCBUlSIcoDXRhTNceZmE9/KYOhcL/sBel4j5EfyAzZtlEN7+GRKKdwVwxDwdyVGaiHx7Zqvcdh3hH/fk+K3bNc6WIDv9Lp3VQN1WY+AxlxIzoC79fhKwUQwjBQ88Jk4Wa0dTR5HweqYQ4ii9jfULN74aYi8ockBHL2gRNGri85tvV3KiHmcJED0qLPhxgDDpAi8rX94tnD8rmyRrR2DqfoGAjdsn8CMQZ/RiB2UclkW9dSGsjV6AuUt817X6K3tnKIBplHVzThUTckYu49bdJRGFsifj5rbn27/OxSTeo6H1+Dbo6ytftNIZueXKZb8LeCRPO+IiFJFQ5ATWPms6sXn93itJqiHK1fOWJL1EomoroNdT0El84dU//q9gpUuuIzPhy8bhNZe2O6ZRuFdaIZpqJ4TOeJhdCf0BetWnxuGPq9YQ== chris" > /home/chris/.ssh/authorized_keys
