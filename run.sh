#!/bin/sh


LOGDIR="perturb_log_files/"
SAVEDIR="save_dir/"
GPU="0"
mkdir -p $LOGDIR

if [ -z "$1" ]
then
    echo "No Run mode provided. Supported : train, perturb"
    echo "Example train command : sh run.sh train <model_type> <dataset>"
    echo "Example perturb command : sh run.sh perturb <model_type> <dataset>"
    exit 0

else
    RUN_MODE=$1
fi

GPU_ARGS=" --gpu "$GPU
if [ "$2" = "s2s" ]
then
    echo "MODELTYPE: "$2
    COMMON_ARGS=$GPU_ARGS" -m seq2seq"
    EVAL_MODEL_ARGS=$COMMON_ARGS" -bs 1 -d True"
    TRAIN_MODEL_ARGS=$COMMON_ARGS" -vmt loss -eps 60 -veps 1 -stim 600 -bs 32 --optimizer adam --lr-scheduler invsqrt -lr 0.005 --dropout 0.3 --warmup-updates 4000"
elif [ "$2" = "s2s_bidir" ]
then
    echo "MODELTYPE: "$2
    COMMON_ARGS=$GPU_ARGS" -m seq2seq --bidirectional true --hiddensize 256"
    EVAL_MODEL_ARGS=$COMMON_ARGS" -bs 1 -d True"
    TRAIN_MODEL_ARGS=$COMMON_ARGS" -vmt loss -eps 60 -veps 1 -stim 600 -bs 32 --optimizer adam --lr-scheduler invsqrt -lr 0.005 --dropout 0.3 --warmup-updates 4000"
elif [ "$2" = "s2s_att_general" ]
then
    echo "MODELTYPE: "$2
    COMMON_ARGS=$GPU_ARGS" -m seq2seq -att general"
    EVAL_MODEL_ARGS=$COMMON_ARGS" -bs 1 -d True"
    TRAIN_MODEL_ARGS=$COMMON_ARGS" -vmt loss -eps 60 -veps 1 -stim 600 -bs 32 --optimizer adam --lr-scheduler invsqrt -lr 0.005 --dropout 0.3 --warmup-updates 4000"
elif [ "$2" = "s2s_att_general_bidir" ]
then
    echo "MODELTYPE: "$2
    COMMON_ARGS=$GPU_ARGS" -m seq2seq -att general --bidirectional true --hiddensize 256"
    EVAL_MODEL_ARGS=$COMMON_ARGS" -bs 1 -d True"
    TRAIN_MODEL_ARGS=$COMMON_ARGS" -vmt loss -eps 60 -veps 1 -stim 600 -bs 32 --optimizer adam --lr-scheduler invsqrt -lr 0.005 --dropout 0.3 --warmup-updates 4000"
elif [ "$2" = "transformer" ]
then
    echo "MODELTYPE: "$2
    COMMON_ARGS=$GPU_ARGS" -m transformer/generator -bs 64"
    EVAL_MODEL_ARGS=$COMMON_ARGS" -bs 64 -d True" 
    TRAIN_MODEL_ARGS=$COMMON_ARGS" --optimizer adam -lr 0.001 --lr-scheduler invsqrt --warmup-updates 4000 -eps 25 -veps 1 -stim 600" 
else
    echo "INVALID modeltype : "$2" Supported : s2s, s2s_att_general, transformer"
    echo "Example train command : sh run.sh train <model_type> <dataset>"
    echo "Example perturb command : sh run.sh perturb <model_type> <dataset>"
    exit 0
fi

if [ -z "$3" ]
then
    echo "No Dataset type specified supplied"
    echo "Example train command : sh run.sh train <model_type> <dataset>"
    echo "Example perturb command : sh run.sh perturb <model_type> <dataset>"
    exit 0
else
    DATASET=$3
    MF=$SAVEDIR"/model_"$3"_"$2
fi

if [ $RUN_MODE = "perturb" ]
then
    echo "MODE : "$RUN_MODE
    for MODEL_TYPE in $2
    do
        for DATATYPE in "test" #valid
        do
            echo "---------------------"
            echo "CONFIG : "$DATASET"_"$MODEL_TYPE"_"$DATATYPE"_NoPerturb"
            LOGFILE=$LOGDIR/log_$DATASET"_"$MODEL_TYPE"_"$DATATYPE"_no_perturb.txt"
            python -W ignore examples/eval_model.py $EVAL_MODEL_ARGS -t $DATASET -mf $MF -sft True -pb "None" --datatype $DATATYPE > $LOGFILE
            grep FINAL_REPORT $LOGFILE

            for PERTURB_TYPE in "only_last" "shuffle" "reverse_utr_order"
            do
                echo "---------------------"
                echo "CONFIG : "$DATASET"_"$MODEL_TYPE"_"$DATATYPE"_"$PERTURB_TYPE
                LOGFILE=$LOGDIR/log_$DATASET"_"$MODEL_TYPE"_"$DATATYPE"_"$PERTURB_TYPE".txt"
                python -W ignore examples/eval_model.py $EVAL_MODEL_ARGS -t $DATASET -mf $MF -sft True -pb $PERTURB_TYPE --datatype $DATATYPE > $LOGFILE
                grep FINAL_REPORT $LOGFILE
            done

            for PERTURB_TYPE in "swap" "repeat" "drop" "worddrop" "verbdrop" "noundrop" "wordshuf" "wordreverse"
            do
                for PERTURB_LOC in "first" "last" "random"
                do
                    echo "---------------------"
                    echo "CONFIG : "$DATASET"_"$MODEL_TYPE"_"$DATATYPE"_"$PERTURB_TYPE"_"$PERTURB_LOC
                    LOGFILE=$LOGDIR/log_$DATASET"_"$MODEL_TYPE"_"$DATATYPE"_"$PERTURB_TYPE"_"$PERTURB_LOC".txt"
                    python -W ignore examples/eval_model.py $EVAL_MODEL_ARGS -t $DATASET -mf $MF -sft True -pb $PERTURB_TYPE"_"$PERTURB_LOC --datatype $DATATYPE > $LOGFILE
                    grep FINAL_REPORT $LOGFILE
                done
            done
        done 
    done
elif [ $RUN_MODE = "train" ]
then
    echo $TRAIN_MODEL_ARGS
    python examples/train_model.py -t $DATASET -mf $MF $TRAIN_MODEL_ARGS
else
    echo "Invalid Run mode provided. Supported : train, perturb"
    echo "Example train command : sh run.sh train <model_type> <dataset>"
    echo "Example perturb command : sh run.sh perturb <model_type> <dataset>"
    exit 0
fi
