# Data feeder utils

## `run-input.sh`

### Purpose: `run-input.sh`

The Bash script monitors an input folder for new `.json` files, publishing their contents to an MQTT input topic.

### Key Components: `run-input.sh`

1. **Configuration**
   - `INPUT_FOLDER`: Directory for incoming `.json` files.
   - `PROCESSED_FOLDER`: Directory for moved files.
   - `MQ_INPUT_TOPIC`: MQTT topic for publishing.

2. **Inotifywait**
   - Listens for file creation/movement events in `INPUT_FOLDER`.

3. **File Processing & MQTT Publishing**
   - Uses `mosquitto_pub` to publish to MQTT broker.

4. **Handling Success/Failure**
   - Moves files to `PROCESSED_FOLDER` if publish succeeds.
   - Displays error message otherwise.

### Prerequisites: `run-input.sh`

- `inotifywait` installed.
- Kubernetes environment for `kubectl` and accessing `mqtt-client` container.

### Usage: `run-input.sh`

1. **Permissions**: `chmod +x run-input.sh`
2. **Run**: `./run-input.sh`

### Notes

- Assumes MQTT version 5 and a Kubernetes environment with a running MQTT broker.
- Customize variables for your environment and adjust security based on broker requirements.
- Assumes .mq-sat file in the local directory with the credentials to access the MQTT broker.
You can obtain the file with `kubectl cp mqtt-client:/var/run/secrets/tokens/..data/mq-sat .mq-sat -n azure-iot-operations`

## `run-output.sh`

### Purpose: `run-output`

The Bash script (`run-output.sh`) subscribes to an MQTT output topic, saves received messages to unique JSON files in an output folder.

### Key Components: `run-output`

1. **Configuration**
   - `MQ_OUTPUT_TOPIC`: MQTT topic to subscribe to.
   - `OUTPUT_FOLDER`: Directory to store output files.

2. **MQTT Subscription**
   - Utilizes `mosquitto_sub` to subscribe to the specified MQTT output topic.
   - Retrieves messages from the broker.

3. **Message Handling & File Saving**
   - For each received message:
     - Generates a unique identifier (UUID) based on the timestamp.
     - Creates a JSON file in the `OUTPUT_FOLDER` with the unique identifier.
     - Saves the received message in the created JSON file.

### Usage: `run-output`

1. **Run Script**: `./run-output.sh <MQ_OUTPUT_TOPIC>`

### Prerequisites: `run-output`

- Assumes a Kubernetes environment with `kubectl` for accessing the `mqtt-client` container.
- MQTT broker details, security credentials (`mq-sat`), and certificate (`ca.crt`) should be set up.

### Notes: `run-output`

- Customize variables according to your environment.
- The script continuously runs, listening for messages on the specified MQTT output topic. If you want to listen for different topics you can execute the script multiple times in parallel.
- Assumes .mq-sat file in the local directory with the credentials to access the MQTT broker.
You can obtain the file with `kubectl cp mqtt-client:/var/run/secrets/tokens/..data/mq-sat .mq-sat -n azure-iot-operations`