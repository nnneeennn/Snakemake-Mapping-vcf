ruleorder: concatenate_lanes1 > concatenate_lanes2 
configfile: "config.yaml"

rule all: 
  input:
    expand('{sample}_{lane}_{R}_001.fastq', sample=config["SAMPLEID"], lane=['L001','L002','L003','L004'], R=['R1','R2']) 

rule concatenate_lanes1: 
  input: 
    expand("{{sample}}_{lane}_{{R}}_001.fastq", lane=['L001','L002','L003','L004'])
  output:
    "{sample}_{R}.cat.fastq"
  shell:
    "cat {input}  > {output}"

rule concatenate_lanes2:
  input:
    expand("{{sample}}_{lane}_{{R}}_001.fastq", lane=['L001','L002'])
  output:
    "{sample}_{R}.cat.fastq"
  shell:
    "cat {input}  > {output}"

rule bwa_map:
  input:
    "{sample}_R1.cat.fastq",
    "{sample}_R2.cat.fastq" 
  output:
    "{sample}_sorted.bam"
  envmodules:
    "bioinfo-tools",
    "bwa/0.7.17",
    "samtools/1.10"
  shell:
    "bash scripts/bwa_map.sh {wildcards.sample} {input[0]} {input[1]} > {output}"

rule index_map_sorted: 
  input: 
    "{sample}_sorted.bam"
  output: 
    "{sample}_sorted.bam.bai"
  envmodules: 
    "bioinfo-tools",
    "samtools/1.10"
  shell:
    "samtools index {input}"

rule mark_duplicates: 
  input:
    "{sample}_sorted.bam"
  output:
    "{sample}_sorted.dedup.bam",
    "{sample}_dup_metrics.txt"   
  envmodules:
    "bioinfo-tools",
    "GATK/4.1.4.1"
  shell: 
    "gatk --java-options -Xmx7g MarkDuplicates \
      -I {input} \
      -O {output[0]} \
      -M {output[1]}"


rule base_recalibration:
  input:
    sample="{sample}_sorted.dedup.bam",
    knownsites="resources_broad_hg38_v0_Homo_sapiens_assembly38_edit.dbsnp138.vcf",
    ref="GRCh38_full.fa"
  output:
    "{sample}.recal.table"
  envmodules:
    "bioinfo-tools",
    "GATK/4.1.4.1"
  shell: 
    "gatk --java-options -Xmx7g BaseRecalibrator -R {input[ref]} -I {input[sample]} --known-sites {input[knownsites]} -O {output}"

rule apply_base_recalibration:
  input:
    sample="{sample}_sorted.dedup.bam",
    table="{sample}.recal.table",
    ref="GRCh38_full.fa"
  output:
    "{sample}.recal.bam"
  envmodules:
    "bioinfo-tools",
    "GATK/4.1.4.1"
  shell:
    "gatk --java-options -Xmx7g ApplyBQSR -R  {input[ref]} -I {input[sample]} --bqsr-recal-file {input[table]} -O {output}"
