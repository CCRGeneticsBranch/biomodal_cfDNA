# Biomodal cfDNA Pipeline

Pipeline for cell-free DNA (cfDNA) analysis using the Biomodal evoC pipeline with downstream variant annotation and copy number analysis.

## Overview

This pipeline performs:
1. **Biomodal evoC**: Runs the official biomodal NextFlow pipeline on biomodal evoC data (https://hpc.nih.gov/apps/biomodal.html)
2. **CNVkit**: Identifies copy number variants
3. **ichorCNA**: Estimates tumor purity and copy number profiles
4. **OpenCravat**: Annotates and filters germline variants using Oncogenomics variant NextFlow pipeline

## How to run

### 1. Initialize a run directory

Creates the work directory and copies config templates:

```bash
bash run_biomodal --runmode=init --workdir=/path/to/my_run
```

### 2. Edit the config files 

- `/path/to/my_run/config/config.yaml` - pipeline parameters and tool paths

Edit the patient, case, and sample IDs.

- `/path/to/my_run/config/samples.tsv` - sample manifest with fastq paths

`config/samples.tsv` requires paired-end fastq files. The manifest file should have two columns:
- **Old**: Original fastq file path(s)
- **New**: Renamed fastq filename(s) (for handling multiple flowcells as lanes)

Example:
```
Old	New
/path/to/sample_R1.fastq.gz	sample_R1.fastq.gz
/path/to/sample_R2.fastq.gz	sample_R2.fastq.gz
```

### 3. Dry run

Validate the workflow:

```bash
bash run_biomodal --runmode=dryrun --workdir=/path/to/my_run
```

### 4. Run on SLURM

Submit the pipeline to the cluster:

```bash
bash run_biomodal --runmode=run --workdir=/path/to/my_run
```

### Additional modes

- `unlock` - Unlock workdir if locked by Snakemake

## Output folders 

Under pipeline output, `results/` subfolder

| Folder | Contents |
|--------|----------|
| **biomodal/nf-input** | Symlinks to input fastq files |
| **biomodal/nf-results** | Biomodal evoC outputs including aligned BAM files and germline VCF |
| **cnvkit** | Copy number variation analysis: segmentation plots and CNV calls |
| **ichorCNA** | Tumor purity estimates and copy number profiles (WIG files and parameters) |
| **Oncogenomics** | OpenCravat variant annotation results organized by patient/case |
