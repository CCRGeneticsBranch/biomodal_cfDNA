# Biomodal cfDNA Pipeline

Snakemake pipeline for cell-free DNA (cfDNA) sequenced with biomodal evoC (duet) chemistry. It runs the proprietary [biomodal Nextflow analysis pipeline](https://software-docs.biomodal.com/) (alignment, deduplication, germline variant calling and methylation), estimates copy number with CNVkit and tumor fraction with ichorCNA, and annotates germline variants with OpenCRAVAT through the Oncogenomics Nextflow workflow.

## Pipeline steps

| Step | Rule | Tool | Description |
|---|---|---|---|
| 1 | `link_raw` |  | Link FASTQs into `results/biomodal/nf-input/`, renaming multiple flowcells as lanes |
| 2 | `biomodal` | biomodal (`biomodal analyse --mode 6bp`) | Alignment to GRCh38 + decoy, deduplication, GATK HaplotypeCaller germline variants and methylation calls |
| 3 | `cnvkit` | CNVkit, samtools | Copy number analysis (flat reference, WGS mode) with scatter plot |
| 4 | `hmmcopy` | HMMcopy `readCounter` | Read counts in 10 kb windows (WIG) on chr1–22, X and Y |
| 5 | `ichorCNA` | ichorCNA | Tumor fraction and copy number profile from the WIG file |
| 6 | `opencravat` | Nextflow, ANNOVAR, OpenCRAVAT | Annotate and filter the germline VCF with the Oncogenomics VCF annotation workflow |

## Requirements

- Runs on NIH [Biowulf](https://hpc.nih.gov/) (SLURM and environment modules).
- Must have access to dependencies listed in [config/config.yaml](config/config.yaml).
- Complete biomodal setup on Biowulf: [Biowulf app page](https://hpc.nih.gov/apps/biomodal.html).

## Installation

```bash
git clone https://github.com/CCRGeneticsBranch/biomodal_cfDNA.git
```

## Quick start

The pipeline is designed to be run in a separate directory (/path/to/my_run).

```bash
# 1. Create a work folder with template config files
bash biomodal_cfDNA/run_biomodal --runmode=init --workdir=/path/to/my_run [--samplesheet=/path/to/samples.tsv]

# 2. Edit /path/to/my_run/config/config.yaml and config/samples.tsv (see Inputs)

# 3. Dry run (writes /path/to/my_run/dryrun.log)
bash biomodal_cfDNA/run_biomodal --runmode=dryrun --workdir=/path/to/my_run

# 4. Submit to SLURM
bash biomodal_cfDNA/run_biomodal --runmode=run --workdir=/path/to/my_run

# Unlock the work folder after an interrupted run
bash biomodal_cfDNA/run_biomodal --runmode=unlock --workdir=/path/to/my_run
```

`-h` shows all options; `-v` prints the pipeline and launcher versions. Per-rule SLURM resources are in `WORKDIR/config/cluster.yaml` (copied from [resources/cluster.yaml](resources/cluster.yaml) at `init`).

## Inputs

Specify one sample per run. Multiple flowcells for that sample may be listed as separate lanes.

### Sample sheet (`config/samples.tsv`)

Tab-separated, one row per FASTQ file (paired-end). All rows belong to the sample named in `config.yaml`.

| Column | Description | Example |
|---|---|---|
| `Original` | Absolute path to the FASTQ file | `/path/to/fastqs/sample1_FLOWCELL1_R1.fastq.gz` |
| `New` | File name for the link in `nf-input/`; must follow the [biomodal FASTQ naming format](https://software-docs.biomodal.com/projects/biomodal-cli/en/latest/guide.html#fastq-filename-format). Give each flowcell its own lane number (`L001`, `L002`, ...) | `sample1_S1_L001_R1_001.fastq.gz` |

### Configuration (`config/config.yaml`)

| Key | Default | Description (source) | Edit? |
|---|---|---|---|
| `sample` | `sample1` | Sample ID; must match the prefix of the `New` FASTQ names | Yes |
| `patient` | `patient1` | Patient ID used for the OpenCRAVAT output folder | Yes |
| `case` | `case1` | Case ID used for the OpenCRAVAT output folder | Yes |
| `ichorCNA_extdata` | `/path/to/ichorCNA/extdata/` | ichorCNA `inst/extdata` (installed from [ichorCNA](https://github.com/broadinstitute/ichorCNA/wiki/Installation)) | Yes |
| `ichorCNA_scripts` | `/data/khanlab3/gb_omics/software/ichorCNA/scripts` | ichorCNA scripts (from [ichorCNA](https://github.com/broadinstitute/ichorCNA)) |  |
| `hmmcopy_readcounter` | `/data/khanlab3/gb_omics/software/hmmcopy_utils/bin/readCounter` | HMMcopy `readCounter` binary ([hmmcopy_utils](https://github.com/shahcompbio/hmmcopy_utils)) |  |
| `oncogenomics_nf` | `/data/khanlab/projects/Nextflow_dev/dev/vg_dev/VCF_Annotation_NF` | Oncogenomics VCF annotation workflow (developed by Vineela Ganagalapudi) |  |
| `opencravat_modules` | `/data/khanlab/projects/ngs_pipeline_testing/opencravat/oc_vg_2.13_install/...` | OpenCRAVAT modules directory ([OpenCRAVAT](https://github.com/KarchinLab/open-cravat)) |  |
| `genome` | `hg38` | Reference for CNVkit; only `hg38` is defined | No |
| `hg38: fasta` | `/data/khanlab3/gb_omics/resources/genomes/hg38/hg38.fa` | Reference FASTA for CNVkit ([UCSC hg38 downloads](https://hgdownload.soe.ucsc.edu/goldenPath/hg38/bigZips/)) | No |
| `hg38: refflat` | `/data/khanlab3/gb_omics/resources/ucsc/hg38/refFlat.txt` | Gene annotation for CNVkit ([UCSC refFlat](https://hgdownload.soe.ucsc.edu/goldenPath/hg38/database/refFlat.txt.gz)) | No |
| `workdir`, `manifest`, `tools`, `cluster` | `WORKDIR/...`, `PIPELINE_HOME/...` | Work folder and launcher/repository paths (filled by `init`) | No  |

## Outputs

All paths are relative to the work folder. `SAMPLE`, `PATIENT` and `CASE` are the values from `config.yaml`.

| Path | Description |
|---|---|
| `results/biomodal/nf-input/` | Renamed links to input FASTQs |
| `results/biomodal/nf-results/duet-1.4.1_SAMPLE_6bp/` | biomodal outputs, including deduplicated BAMs (`sample_outputs/bams/`), germline VCFs (`sample_outputs/variant_call_files/germline/`) and methylation files (`sample_outputs/modc_quantification/`) |
| `results/cnvkit/` | CNVkit copy number segments, calls, and scatter plot |
| `results/ichorCNA/SAMPLE.10000.wig` | Read counts in 10 kb windows |
| `results/ichorCNA/SAMPLE.params.txt` | ichorCNA tumor fraction and ploidy estimates (other ichorCNA outputs are in the same folder) |
| `results/Oncogenomics/PATIENT/CASE/` | OpenCRAVAT annotation results (`PATIENT/db/PATIENT.variants`) |
| `results/pipeline_version.txt` | Pipeline version used for the run |
| `runinfo.yaml`, `snakemake.log`, `logs/` | Run information, Snakemake log and per-rule SLURM logs |

## Tools and references

Modules are listed in [resources/tools.yaml](resources/tools.yaml).

| Tool | Module / source | Used in | Reference |
|---|---|---|---|
| Snakemake | `snakemake/7.19.1` | workflow | Mölder et al. 2021, *F1000Research* [doi:10.12688/f1000research.29032.2](https://doi.org/10.12688/f1000research.29032.2) |
| biomodal duet pipeline | `biomodal` | `biomodal` | Füllgrabe et al. 2023, *Nat Biotechnol* [doi:10.1038/s41587-022-01652-0](https://doi.org/10.1038/s41587-022-01652-0) |
| CNVkit | `cnvkit` | `cnvkit` | Talevich et al. 2016, *PLoS Comput Biol* [doi:10.1371/journal.pcbi.1004873](https://doi.org/10.1371/journal.pcbi.1004873) |
| SAMtools | `samtools` | `cnvkit` | Danecek et al. 2021, *GigaScience* [doi:10.1093/gigascience/giab008](https://doi.org/10.1093/gigascience/giab008) |
| HMMcopy `readCounter` | `hmmcopy_readcounter` | `hmmcopy` | [hmmcopy_utils source repository](https://github.com/shahcompbio/hmmcopy_utils) |
| ichorCNA | `R` + `ichorCNA_scripts` | `ichorCNA` | Adalsteinsson et al. 2017, *Nat Commun* [doi:10.1038/s41467-017-00965-y](https://doi.org/10.1038/s41467-017-00965-y) |
| Nextflow | `nextflow` | `opencravat` | Di Tommaso et al. 2017, *Nat Biotechnol* [doi:10.1038/nbt.3820](https://doi.org/10.1038/nbt.3820) |
| ANNOVAR | `annovar` | `opencravat` | Wang et al. 2010, *Nucleic Acids Res* [doi:10.1093/nar/gkq603](https://doi.org/10.1093/nar/gkq603) |
| OpenCRAVAT | `opencravat_modules` | `opencravat` | Pagel et al. 2020, *JCO Clin Cancer Inform* [doi:10.1200/CCI.19.00132](https://doi.org/10.1200/CCI.19.00132) |

## Versioning

The pipeline version is in [VERSION](VERSION) and changes are listed in [CHANGELOG.md](CHANGELOG.md). Each run records the pipeline version, git commit and launcher version in `runinfo.yaml` and `results/pipeline_version.txt`. The launch script is a copy of [biowulf-snakemake-launcher](https://github.com/CCRGeneticsBranch/biowulf-snakemake-launcher) (`bin/launcher.sh`).

## Contact

Erica Pehrsson, Genetics Branch, Center for Cancer Research, National Cancer Institute. Please report problems through GitHub issues.
