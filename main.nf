# Import python libraries
import os
from os.path import join
import itertools
import yaml
import pandas as pd

# Set directories
WORKDIR = config["workdir"]
RESULTSDIR = join(WORKDIR,"results")
SCRIPTSDIR = config["scriptsdir"]

# Get sample
SAMPLE = config["sample"]

# Get fastq location
manifest = pd.read_table(config["manifest"])
fastqs = manifest['New'].tolist()

# Define tools
with open(config["tools"]) as f:
    TOOLS = yaml.safe_load(f)

# Define resources per rule
with open(config["cluster"]) as f:
    CLUSTER = yaml.safe_load(f)

getthreads=lambda rname:int(CLUSTER[rname]["threads"]) if rname in CLUSTER and "threads" in CLUSTER[rname] else int(CLUSTER["__default__"]["threads"])
getmemg=lambda rname:CLUSTER[rname]["mem"] if rname in CLUSTER and "mem" in CLUSTER[rname] else CLUSTER["__default__"]["mem"]

# Define genomes
genome = config['genome']

# Rules
localrules: link_raw

rule all:
    input:
        # Link fastqs
        expand(join(RESULTSDIR, "biomodal", "nf-input", "{fastq}"),fastq=fastqs),
        
        # Biomodal
        expand(join(RESULTSDIR, "biomodal", "nf-results", "duet-1.4.1_{sample}_6bp","sample_outputs","bams","{sample}.genome.GRCh38Decoy_primary_assembly.dedup.bam"),sample=[SAMPLE]),
        expand(join(RESULTSDIR, "biomodal", "nf-results", "duet-1.4.1_{sample}_6bp","sample_outputs","variant_call_files","germline","{sample}.genome.GRCh38Decoy_primary_assembly.dedup.vcf.gz"),sample=[SAMPLE]),

        # CNVkit
        expand(join(RESULTSDIR, "cnvkit", "{sample}.genome.GRCh38Decoy_primary_assembly.dedup-scatter.png"),sample=[SAMPLE]),

        # OpenCravat
        expand(join(RESULTSDIR, "OpenCravat", "{sample}.genome.GRCh38Decoy_primary_assembly.dedup.vcf.gz.tsv"),sample=[SAMPLE]),
        expand(join(RESULTSDIR, "OpenCravat", "{sample}.all_annotations.txt"),sample=[SAMPLE]),
        expand(join(RESULTSDIR, "OpenCravat", "{sample}.rare_annotation.tsv"),sample=[SAMPLE]),

        # ichorCNA
        expand(join(RESULTSDIR, "ichorCNA", "{sample}.10000.wig"),sample=[SAMPLE]),
        expand(join(RESULTSDIR, "ichorCNA", "{sample}.params.txt"),sample=[SAMPLE])

rule link_raw:
    """
    Link fastqs from storage to Biomodal nf-input, renaming multiple flowcells as lanes
    """
    input:
        manifest = config["manifest"]
    output:
        fastq = expand(join(RESULTSDIR, "biomodal", "nf-input", "{fastq}"),fastq=fastqs)
    params:
        outdir = join(RESULTSDIR, "biomodal", "nf-input")
    shell:
        """
        while read old new
        do
            ln -s $old {params.outdir}/$new
        done < <(tail -n +2 {input.manifest})
        """


