#cloud-config
package_update: true
package_upgrade: true

packages:
  - openjdk-21-jre-headless
  - screen

write_files:
  - path: ${PERSISTENT_VOLUME_PATH}/start_minecraft.sh
    permissions: '0755'
    content: |
      #!/bin/bash
      cd ${PERSISTENT_VOLUME_PATH}
      java -Xmx1024M -Xms1024M -jar minecraft_server.1.21.1.jar --nogui 
  - path: ${PERSISTENT_VOLUME_PATH}/server.properties
    permission: '0755'
    content: |
      difficulty=normal
      white-list=true
  - path: ${PERSISTENT_VOLUME_PATH}/ops.json
    permission: '0755'
    content: |
      [
        {
          "uuid": "${ADMIN_UUID}",
          "name": "${ADMIN_USER}",
          "level": 4
        }
      ]

runcmd:
  - mkdir -o ${PERSISTENT_VOLUME_PATH}
  - cd ${PERSISTENT_VOLUME_PATH}
  - wget -O minecraft_server.1.21.1.jar https://piston-data.mojang.com/v1/objects/59353fb40c36d304f2035d51e7d6e6baa98dc05c/server.jar
  - echo "eula=true" > ${PERSISTENT_VOLUME_PATH}/eula.txt
  - bash ${PERSISTENT_VOLUME_PATH}/start_minecraft.sh

final_message: "Minecraft server setup complete!"
