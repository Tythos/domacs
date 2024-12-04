#cloud-config
package_update: true
package_upgrade: true

packages:
  - openjdk-21-jre-headless
  - screen

write_files:
  - path: /root/mount_persistent_volume.sh
    permissions: '0755'
    content: |
      #!/bin/bash
      mkdir -p /mnt/${PERSISTENT_VOLUME_NAME}
      mount /dev/disk/by-id/scsi-0DO_Volume_${PERSISTENT_VOLUME_NAME} /mnt/${PERSISTENT_VOLUME_NAME}
      echo "/dev/disk/by-id/scsi-0DO_Volume_${PERSISTENT_VOLUME_NAME} /mnt/${PERSISTENT_VOLUME_NAME} ext4 defaults,nofail 0 2" >> /etc/fstab
  - path: /root/server.properties
    permissions: '0755'
    content: |
      difficulty=normal
      white-list=true
  - path: /root/ops.json
    permissions: '0755'
    content: |
      [
        {
          "uuid": "${ADMIN_UUID}",
          "name": "${ADMIN_USER}",
          "level": 4
        }
      ]
  - path: /root/whitelist.json
    permissions: '0644'
    content: |
      [
        {
            "uuid": "d133e3ac-5616-4d38-a979-0ee17d4c766e",
            "name": "PinkGalaxy71277"
        },
        {
            "uuid": "5a18fba5-3949-4942-a94d-882f3204edbc",
            "name": "NdersGame"
        }
      ]
  - path: /root/eula.txt
    permissions: '0644'
    content: |
      eula=true
  - path: /root/start_minecraft_server.sh
    permissions: '0755'
    content: |
      #!/bin/bash
      cd ${PERSISTENT_VOLUME_PATH}
      wget -O minecraft_server.1.21.4.jar https://piston-data.mojang.com/v1/objects/4707d00eb834b446575d89a61a11b5d548d8c001/server.jar
      java -Xmx1024M -Xms1024M -jar minecraft_server.1.21.4.jar --nogui

runcmd:
  - ls -ahl /root
  - /root/mount_persistent_volume.sh
  - mkdir -p ${PERSISTENT_VOLUME_PATH}
  - cp -n /root/server.properties ${PERSISTENT_VOLUME_PATH}/server.properties
  - cp -n /root/ops.json ${PERSISTENT_VOLUME_PATH}/ops.json
  - cp -n /root/whitelist.json ${PERSISTENT_VOLUME_PATH}/whitelist.json
  - cp -n /root/eula.txt ${PERSISTENT_VOLUME_PATH}/eula.txt
  - /root/start_minecraft_server.sh

final_message: "Minecraft server setup complete!"
