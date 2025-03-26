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
      gamemode=survival
      difficulty=normal
      white-list=true
      enable-command-block=false
      max-players=20

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
      curl https://piston-data.mojang.com/v1/objects/e6ec2f64e6080b9b5d9b471b291c33cc7f509733/server.jar -o minecraft_server.1.21.5.jar
      #curl https://meta.fabricmc.net/v2/versions/loader/1.21.4/0.16.9/1.0.1/server/jar -o fabric-server-mc.1.21.4-loader.0.16.9-launcher.1.0.1.jar
      #curl https://mediafilez.forgecdn.net/files/5966/280/fabric-api-0.111.0%2B1.21.4.jar -o mods/fabric-api-0.111.0+1.21.4.jar
      #curl https://mediafilez.forgecdn.net/files/5876/845/geckolib-fabric-1.21.3-4.7.1.jar -o mods/geckolib-fabric-1.21.3-4.7.1.jar
      #curl https://mediafilez.forgecdn.net/files/5512/147/duckling-fabric-1.21-5.0.1.jar -o mods/duckling-fabric-1.21-5.0.1.jar
      #curl https://mediafilez.forgecdn.net/files/5969/929/GlitchCore-fabric-1.21.4-2.3.0.0.jar -o mods/GlitchCore-fabric-1.21.4-2.3.0.0.jar
      #curl https://mediafilez.forgecdn.net/files/5861/336/SereneSeasons-fabric-1.21.3-10.2.0.1.jar -o mods/SereneSeasons-fabric-1.21.3-10.2.0.1.jar
      java -Xmx1024M -Xms1024M -jar minecraft_server.1.21.5.jar --nogui
      #java -Xmx2G -jar fabric-server-mc.1.21.4-loader.0.16.9-launcher.1.0.1.jar nogui
  - path: /etc/systemd/system/minecraft.service
    content: |
      [Unit]
      Description=Minecraft Server
      After=network.target
      
      [Service]
      ExecStart=/root/start_minecraft_server.sh
      User=root
      Restart=always

      [Install]
      WantedBy=multi-user.target


runcmd:
  - ls -ahl /root
  - /root/mount_persistent_volume.sh
  - mkdir -p ${PERSISTENT_VOLUME_PATH}
  - cp -n /root/server.properties ${PERSISTENT_VOLUME_PATH}/server.properties
  - cp -n /root/ops.json ${PERSISTENT_VOLUME_PATH}/ops.json
  - cp -n /root/whitelist.json ${PERSISTENT_VOLUME_PATH}/whitelist.json
  - cp -n /root/eula.txt ${PERSISTENT_VOLUME_PATH}/eula.txt
  - systemctl enable minecraft.service
  - systemctl start minecraft.service

final_message: "Minecraft server setup complete!"
