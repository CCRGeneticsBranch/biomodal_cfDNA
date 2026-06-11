# Biomodal cfDNA Pipeline

Pipeline for cell-free DNA (cfDNA) analysis using the Biomodal evoC pipeline with downstream variant annotation and copy number analysis.

## Overview

This pipeline performs:
1. **Biomodal evoC**: Runs the proprietary biomodal NextFlow pipeline on biomodal evoC data (https://software-docs.biomodal.com/projects/biomodal-cli/en/latest/guide.html, https://hpc.nih.gov/apps/biomodal.html)
2. **CNVkit**: Identifies copy number variants (flat reference, WGS mode)
3. **ichorCNA**: Estimates tumor purity and copy number profiles (10kb bins)
4. **OpenCravat**: Runs Oncogenomics-based NextFlow workflow to annotate germline variants with OpenCravat and filter

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
- **Old**: Original fastq file path
- **New**: Renamed fastq - required for handling multiple flowcells as lanes (https://software-docs.biomodal.com/projects/biomodal-cli/en/latest/guide.html#fastq-filename-format)

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

Under pipeline output `results/` subfolder:

| Folder | Contents |
|--------|----------|
| **biomodal/nf-input** | Symlinks to input fastq files |
| **biomodal/nf-results** | Biomodal evoC outputs, including aligned BAM files, GATK HaplotypeCaller germline VCF, and DNA methylation values |
| **cnvkit** | Copy number variation analysis: segmentation plots and CNV calls |
| **ichorCNA** | Tumor purity estimates and copy number profiles (WIG files and parameters) |
| **Oncogenomics** | OpenCravat variant annotation results organized by patient/case |
