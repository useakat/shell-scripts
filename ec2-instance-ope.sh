#!/bin/bash

INSTANCE_ID="i-01166463ddfaed9eb"  # RNAseq instance

# --- Functions ---

# Function to display help message
show_help() {
    echo "Usage: $0 <command> [options]"
    echo ""
    echo "Commands:"
    echo "  start [instance_type]   Start the EC2 instance. Optionally change the instance type before starting."
    echo "  stop                    Stop the EC2 instance."
    echo "  status                  Get the current status of the EC2 instance."
    echo "  help, -h                Show this help message."
    echo ""
    echo "Options:"
    echo "  instance_type           Specify the new instance type (e.g., t2.micro, t3.large). This can only be done when the instance is stopped."
}

# Function to get the current instance state
get_instance_state() {
    aws ec2 describe-instances --instance-ids "${INSTANCE_ID}" --query "Reservations[0].Instances[0].State.Name" --output text
}

# --- Main Script ---

OPERATION=$1
INSTANCE_TYPE=$2

# Show help if no arguments are provided or if help is requested
if [ -z "$OPERATION" ] || [ "$OPERATION" = "help" ] || [ "$OPERATION" = "-h" ]; then
    show_help
    exit 0
fi

# Get and show current instance status
CURRENT_STATE=$(get_instance_state)
echo "Instance ${INSTANCE_ID} is currently: ${CURRENT_STATE}"

case "$OPERATION" in
    start)
        # If an instance type is specified, modify it before starting
        if [ -n "$INSTANCE_TYPE" ]; then
            if [ "$CURRENT_STATE" = "stopped" ]; then
                echo "Attempting to change instance type to ${INSTANCE_TYPE}..."
                aws ec2 modify-instance-attribute --instance-id "${INSTANCE_ID}" --instance-type "{\"Value\": \"${INSTANCE_TYPE}\"}"
                echo "Instance type changed successfully."
            else
                echo "Warning: Instance must be stopped to change its type. Ignoring type change."
            fi
        fi

        echo "Starting instance ${INSTANCE_ID}..."
        aws ec2 start-instances --instance-ids "${INSTANCE_ID}"
        echo "Waiting for instance to be ready..."
        sleep 20
        echo "Connecting via SSH..."
        ssh-ec2.sh
        ;;
    stop)
        if [ -n "$INSTANCE_TYPE" ]; then
            echo "Warning: Instance type can only be changed with the 'start' command. Ignoring type change."
        fi
        echo "Stopping instance ${INSTANCE_ID}..."
        aws ec2 stop-instances --instance-ids "${INSTANCE_ID}"
        ;;
    status)
        # The status has already been printed above.
        exit 0
        ;;
    *)
        echo "Error: Invalid command."
        show_help
        exit 1
        ;;
esac
