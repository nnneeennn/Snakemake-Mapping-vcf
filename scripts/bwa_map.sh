#!/bin/bash
INDIV=$1

bwa mem -R'@RG\tID:${INDIV}}_1\tSM:${INDIV}\tPL:ILLUMINA\tLB:lib1\tPU:2021-09-30' \
	-t 10 GRCh38_full.fa \
	$2 \
	$3 \
        | samtools sort 
