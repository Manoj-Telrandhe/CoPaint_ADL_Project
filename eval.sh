#!/bin/bash

# Directories for datasets
INPUT_FOLDER="./hyperparam_eval/images"
OUTPUT_FOLDER="./hyperparam_eval/results"
CELEBAHQ_CONFIG="./configs/celebahq.yaml"
IMAGENET_CONFIG="./configs/imagenet.yaml"

# Algorithm list
ALGORITHMS=("repaint" "ddim" "o_ddim" "resample" "ddnm" "ddrm" "dps")
JUMP_LENGTHS=(5 10 20)  # Example jump_len values
JUMP_SAMPLES=(1 2 3)    # Example jump_n_sample values
NUM_ITERATIONS=(2 5 8)    # Example num_iteration_optimize_xt values
LR_XT=(0.01 0.02 0.03)       # Example lr_xt values

# Create results folder if not exists
mkdir -p $OUTPUT_FOLDER

# Loop over datasets, algorithms, jump_len, jump_n_sample, num_iteration_optimize_xt, and lr_xt
for DATASET in "celebahq" "imagenet"; do
    if [ "$DATASET" == "celebahq" ]; then
        CONFIG_FILE=$CELEBAHQ_CONFIG
        IMAGE_EXT="jpg"
        MASK_FILE="$INPUT_FOLDER/celebahq-mask.jpg"
    else
        CONFIG_FILE=$IMAGENET_CONFIG
        IMAGE_EXT="JPEG"
        MASK_FILE="$INPUT_FOLDER/imagenet-mask.jpg"
    fi

    # Check if the mask file exists
    if [ ! -f "$MASK_FILE" ]; then
        echo "Error: Mask file $MASK_FILE does not exist."
        exit 1
    fi

    # Loop through all images in the dataset folder
    for INPUT_IMAGE in $INPUT_FOLDER/${DATASET}/*.${IMAGE_EXT}; do
        # Extract image name from the full path
        IMAGE_NAME=$(basename $INPUT_IMAGE)

        for ALGO in "${ALGORITHMS[@]}"; do
            for JUMP_LEN in "${JUMP_LENGTHS[@]}"; do
                for JUMP_SAMPLE in "${JUMP_SAMPLES[@]}"; do
                    for NUM_ITER in "${NUM_ITERATIONS[@]}"; do
                        for LR in "${LR_XT[@]}"; do
                            # Create a unique output folder for each setting
                            OUTPUT_DIR="$OUTPUT_FOLDER/${DATASET}_${ALGO}_jump${JUMP_LEN}_sample${JUMP_SAMPLE}_iter${NUM_ITER}_lr${LR}_${IMAGE_NAME%.*}"
                            mkdir -p $OUTPUT_DIR

                            # Run the python script with the current settings
                            python main.py --config_file $CONFIG_FILE \
                                --input_image $INPUT_IMAGE \
                                --mask_type half \
                                --mask $MASK_FILE \
                                --outdir $OUTPUT_DIR \
                                --n_samples 1 \
                                --algorithm $ALGO \
                                --ddim.schedule_params.jump_length $JUMP_LEN \
                                --ddim.schedule_params.jump_n_sample $JUMP_SAMPLE \
                                --ddim.schedule_params.use_timetravel \
                                --optimize_xt.num_iteration_optimize_xt $NUM_ITER \
                                --optimize_xt.lr_xt $LR
                        done
                    done
                done
            done
        done
    done
done
