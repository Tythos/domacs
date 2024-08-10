# DOMACS

## The DigitalOcean Minecraft Automated Compute Server

### Verification upon deployment

SSH into VM:

```sh
terraform output -raw PRIVATE_SSH_KEY > id_rsa
ssh -i id_rsa root@$(terraform output VM_IP_ADDR)
```

Check cloud-init logs:

```sh
tail -f /var/log/cloud-init.log
tail -f /var/log/cloud-init-output.log
```

Verify the Minecraft process is running:

```sh
screen -ls
ps aux | grep java
```

Check Minecraft server logs:

```sh
tail -f /opt/minecraft/logs/latest.log
```

Verify EULA acceptance:

```sh
cat /opt/minecraft/eula.txt
```
