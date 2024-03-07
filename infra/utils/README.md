# Utils

This README contains information to guide you through the use of the `utils` folder content.
Some content may only be available for debugging purposes. 

## get-dp-logs.sh Usage Guide

`get-dp-logs.sh` is a bash script used to retrieve logs from a specific pipeline. It accepts several command-line options.

### Command-line Options

- `-p`: Specifies the pipeline ID.
- `-s`: Specifies the stage ID.
- `-e`: Specifies the event type.
- `-c`: Specifies any custom parameters.

### Usage Example

```bash
./get-dp-logs.sh -p <pipeline_id> -s <stage_id> -e <event_type> -c <custom_parameters>
```
